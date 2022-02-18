#ifndef TOON_LIGHTING
#define TOON_LIGHTING

#include "ToonSurfaceData.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"



//扁平化的间接光照，留作对比
half3 ShadeGI(ToonSurfaceData surfaceData)
{
    // hide 3D feeling by ignoring all detail SH (leaving only the constant SH term)
    // we just want some average envi indirect color only
    half3 averageSH = SampleSH(0);

    // can prevent result becomes completely black if lightprobe was not baked 
    averageSH = max(_IndirectLightMinColor,averageSH);

    // occlusion (maximum 50% darken for indirect to prevent result becomes completely black)
    half indirectOcclusion = lerp(1, surfaceData.occlusion, 0.5);
    return averageSH * indirectOcclusion;
}


half3 DirectDiffuseWithoutAlbedo(ToonSurfaceData surfaceData, InputData inputData, Light light, half NdotL, half2 rampV)
{
    //lambertDiffuse    
#ifdef _USE_RAMPMAP

    half shadowWeight = surfaceData.lightMap.g;
    //half shadowAttenuation = 0.5 * NdotL + 0.5;
    //half shadowAttenuation = (NdotL * shadowWeight) * 0.5;
    //就这两小步好像确实没必要lerpstep的样子
    // if(shadowWeight > 0.95)
    //     shadowAttenuation = 1;
    // if(shadowWeight < 0.05)
    //     shadowAttenuation = 0;
    //我服了，搞不出来，先妥协了
    half shadowAttenuation = NdotL;
    //shadowAttenuation = lerp(0, 1, (shadowWeight + NdotL) * 0.5 );

    half3 rampColor;
    half time = 1;
    
    if(shadowAttenuation < _LightArea && shadowWeight < 0.95)
    {
        //原公式 ：
        half rampWidthRatio = max(surfaceData.vertexColor.y * 2, 0.01);
        rampWidthRatio = lerp(1, rampWidthRatio, _UseVertexRampWidth);
        shadowAttenuation = 1 - min((-shadowAttenuation + _LightArea) / _LightArea / rampWidthRatio, 1);
        //shadowAttenuation /= _LightArea;
        if(time)
        {
            rampColor = _RampMap.Sample(sampler_RampMap, half2(shadowAttenuation, rampV.x)).rgb;
            half3 rampColor2 = _RampMap.Sample(sampler_RampMap, half2(shadowAttenuation, rampV.y)).rgb;
            rampColor = lerp(rampColor2, rampColor, _ColorTone);
        }
        
    }
    else
    { 
        rampColor = 1;
    }

    //接受投影，先这样吧，目前效果最能接受的办法了
    //half3 shadowColor = _RampMap.Sample(sampler_RampMap, half2(shadowAttenuation, rampV));
    half3 ShadowColor2 = _RampMap.Sample(sampler_RampMap, half2(0, rampV.x)).rgb;
    half3 shadowColor = lerp(ShadowColor2, rampColor, shadowWeight * 2);
    //half3 shadowColor = lightShadowColor + (rampColor - lightShadowColor) * light.shadowAttenuation;
#else
    half litOrShadowMark = smoothstep(_CelShadeMidPoint-_CelShadeSoftness,_CelShadeMidPoint+_CelShadeSoftness, NdotL);
    // light's shadow map
    litOrShadowMark *= lerp(1, light.shadowAttenuation, _ReceiveShadowMappingAmount);
    //shadow Color
    half3 shadowColor = lerp(_ShadowMapColor, 1, litOrShadowMark);

    half distanceAttenuation = min(4, light.distanceAttenuation);
    shadowColor *= light.distanceAttenuation;
#endif
    

    return shadowColor;
}

half3 DirectSpecular(ToonSurfaceData surfaceData, InputData inputData , half3 lightDirWS, half4 specColorPower)
{
    //blinnPhongSpecular
    half3 halfNormal = normalize(lightDirWS + inputData.viewDirectionWS);  
    half3 specular = pow(saturate(dot(inputData.normalWS, halfNormal)), specColorPower.w);
    //specularColor *= surfaceData.lightMap.b;
    specular *= (1 - surfaceData.lightMap.b < specular);
    specular *= surfaceData.lightMap.r * specColorPower.rgb;
    return specular;
}


half3 ToonSurfaceShading(ToonSurfaceData surfaceData, InputData inputData, half NdotL, half2 rampV, half4 specColorPower)
{
    // Indirect lighting
    
 #ifdef _USE_NORMALSH
     half3 IndirectDiffuse = inputData.bakedGI * surfaceData.occlusion;
 #else
    half3 IndirectDiffuse = ShadeGI(surfaceData);
#endif

    // Main light is the brightest directional light.
    // It is shaded outside the light loop and it has a specific set of variables and shading path
    // so we can be as fast as possible in the case when there's only a single directional light
    // You can pass optionally a shadowCoord. If so, shadowAttenuation will be computed.
    // To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
#if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
    half4 shadowMask = inputData.shadowMask;
#elif !defined (LIGHTMAP_ON)
    half4 shadowMask = unity_ProbesOcclusion;
#else
    half4 shadowMask = half4(1, 1, 1, 1);
#endif
    
    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);

    //float3 shadowTestPosWS = inputData.positionWS + mainLight.direction * (_ReceiveShadowMappingPosOffset + _IsFace);
    //https://www.bilibili.com/read/cv6436088/

    // Main light
    half3 directDiffuse = DirectDiffuseWithoutAlbedo(surfaceData, inputData, mainLight, NdotL, rampV);
    
    // All additional lights

    half3 additionalLightSumResult = 0;

// #ifdef _ADDITIONAL_LIGHTS
//     // Returns the amount of lights affecting the object being renderer.
//     // These lights are culled per-object in the forward renderer of URP.
//     int additionalLightsCount = GetAdditionalLightsCount();
//     for (int i = 0; i < additionalLightsCount; ++i)
//     {
//         // Similar to GetMainLight(), but it takes a for-loop index. This figures out the
//         // per-object light index and samples the light buffer accordingly to initialized the
//         // Light struct. If ADDITIONAL_LIGHT_CALCULATE_SHADOWS is defined it will also compute shadows.
//         int perObjectLightIndex = GetPerObjectLightIndex(i);
//         Light light = GetAdditionalPerObjectLight(perObjectLightIndex, lightingData.positionWS); // use original positionWS for lighting
//         light.shadowAttenuation = AdditionalLightRealtimeShadow(perObjectLightIndex, shadowTestPosWS); // use offseted positionWS for shadow test
//
//         // Different function used to shade additional lights.
//         additionalLightSumResult += ShadeSingleLight(surfaceData, lightingData, light, true);
//     }
// #endif

    half3 finColor;
    
    //specular Flow
    if(surfaceData.lightMap.x > 0.90)
    {
        //用逆转置是正确的，但是就效果表现上不需要那么精确，因此直接用V矩阵也没什么毛病
        half3 normalVS = mul(UNITY_MATRIX_IT_MV, inputData.normalWS);
        //half3 normalVS = mul(UNITY_MATRIX_V, inputData.normalWS);
        half2 MT_UV = half2(normalVS.y * 1, normalVS.z) * 0.5 + 0.5;

        finColor = saturate(_MT.Sample(sampler_MT, MT_UV) * _Metal_Brightness);
        //r6//r13
        finColor = lerp(_Metal_DarkColor, _Metal_LightColor, finColor) * surfaceData.albedo;
        //暂时没算__ES_CharacterMainLightBrightness
        half lightAttenuation = (NdotL + 0.5) * 0.5;
        finColor = lerp(finColor * _Metal_SpecAttenInShadow, finColor, lightAttenuation);
    
    
        half3 halfNormal = normalize(mainLight.direction + inputData.viewDirectionWS);  
        half spec = pow(saturate(dot(inputData.normalWS, halfNormal)), _Metal_SpecPower);

        //要处理高光在阴影内衰减
        //r0
        finColor += min(spec * 60, 1) * _Metal_SpecColor * surfaceData.lightMap.z; //* _Metal_SpecAttenInShadow * __ES_CharacterMainLightBrightness
        finColor = lerp(finColor, finColor * surfaceData.emission, surfaceData.alpha);
    }
    //diffuse Flow
    else
    {
        //half3 diffuse = (IndirectDiffuse + directDiffuse) * surfaceData.albedo;
        half3 diffuse = directDiffuse * surfaceData.albedo;
        half3 specular = DirectSpecular(surfaceData, inputData, mainLight.direction, specColorPower);
        finColor = diffuse + specular;
    
        //alpha标记emission
        finColor = lerp(finColor * lerp(1, mainLight.color, _LightRatio), finColor * surfaceData.emission, surfaceData.alpha);
    
        half maxChannel = max(finColor.r, finColor.g);
        maxChannel = max(maxChannel, finColor.b);
        if(maxChannel > 1)
            finColor /= maxChannel;
    }

    return finColor; //*ambientBrightness 
    //return CompositeAllLightResults(indirectResult, mainLightResult, additionalLightSumResult, emissionResult, surfaceData, lightingData);
}

half3 ToonFaceShading(ToonSurfaceData surfaceData, half3 faceForward, half3 faceLeft, half2 uv)
{
    Light light = GetMainLight();
    half3 faceLightDir = half3(light.direction.x, 0, light.direction.z);
    half faceLightAtten = 1 - (dot(faceLightDir, faceForward) * 0.5 + 0.5);

    //SDF只记录了左侧光照阴影的情况，在右侧需要反转UV来计算
    half flipU = sign(dot(faceLightDir, faceLeft));
    half shadowRamp = GetSDFFaceShadowRamp(uv * half2(flipU, 1));

    half faceShadow = step(faceLightAtten, shadowRamp);

    return lerp(surfaceData.albedo * _FaceShadowMultiCol, surfaceData.albedo, faceShadow) * lerp(1, light.color, _LightRatio);
    return (half3(0.9, 0.51, 0.51)) * faceShadow;
    return faceShadow;
}


#endif