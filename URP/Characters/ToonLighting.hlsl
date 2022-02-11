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
            rampColor2 = (rampColor - rampColor2) * _ColorTone;
            rampColor = rampColor + rampColor2;
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

    
    //specular *= surfaceData.lightMap.b;

    //==============================================================================================
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
    //==============================================================================================

    // emission
    //half3 emissionResult = ShadeEmission(surfaceData, lightingData);

    half3 diffuse = (IndirectDiffuse + directDiffuse) * surfaceData.albedo;
    half3 specular = DirectSpecular(surfaceData, inputData, mainLight.direction, specColorPower);

    half3 finColor = (diffuse + specular) * ((mainLight.color - 1) * 0.3 + 1);
    //return specular;
    //return directLight;
    //return directLight * surfaceData.albedo;
    return finColor; //*ambientBrightness 
    //return CompositeAllLightResults(indirectResult, mainLightResult, additionalLightSumResult, emissionResult, surfaceData, lightingData);
}



#endif