#ifndef TOON_LIGHTING
#define TOON_LIGHTING

#include "ToonSurfaceData.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#define SKIN_RAMP_LAYER 1

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

/// <summary>
/// 这逻辑。。。。晕
/// </summary>
half GetYSRampMapLayer(half rampMask, half4 rampMapLayerSwitch)
{
    half4 condition1 = rampMask.xxxx >= half4(0.80, 0.60, 0.40, 0.20);
    half3 condition2  = rampMask.xxx     <     half3(0.80, 0.60, 0.40);
    
    half finalLayer = lerp(1         , 2, condition1.x                * rampMapLayerSwitch.x);
         finalLayer = lerp(finalLayer, 5, condition1.y * condition2.x * rampMapLayerSwitch.y);
         finalLayer = lerp(finalLayer, 3, condition1.z * condition2.y * rampMapLayerSwitch.z);
         finalLayer = lerp(finalLayer, 4, condition1.w * condition2.z * rampMapLayerSwitch.w);

    return finalLayer;
}

half3 DirectlightWithOutAlbedo(ToonSurfaceData surfaceData, InputData inputData, Light light, half NdotL)
{
    //half NdotL = dot(inputData.normalWS, light.direction);
    half3 halfNormal = normalize(light.direction + inputData.viewDirectionWS);

    //lambertDiffuse    
#ifndef _USE_RAMPMAP
    half litOrShadowMark = smoothstep(_CelShadeMidPoint-_CelShadeSoftness,_CelShadeMidPoint+_CelShadeSoftness, NdotL);
    // light's shadow map
    litOrShadowMark *= lerp(1, light.shadowAttenuation, _ReceiveShadowMappingAmount);
    //shadow Color
    half3 shadowColor = lerp(_ShadowMapColor, 1, litOrShadowMark);

    half distanceAttenuation = min(4, light.distanceAttenuation);
    shadowColor *= light.distanceAttenuation;
#else
    #ifdef _ISFACE
    half rampLayer = GetYSRampMapLayer(SKIN_RAMP_LAYER, _RampMapLayerSwitch);
    #else
    half rampLayer = GetYSRampMapLayer(surfaceData.lightMap.a, _RampMapLayerSwitch);
    #endif
    
    half rampV;

    float time = 1;
    if(time)
    {
        //逻辑还算简单，-1是为了把坐标起点映射到0
        //*0.1是为了把坐标缩放到0 ~ 1
        //+0.05是为了是采样点位于ramp中部
        //1-其实是因为uv和ramp顺序是反的，也可以直接反转纹理
        rampV = 1 - ((rampLayer - 1) * 0.1 + 0.05);
    }
    
    //half shadowAttenuation = 0.5 * NdotL + 0.5;
    half shadowAttenuation = (NdotL + 0.5) * 0.5;
    if(shadowAttenuation < _LightArea)
    {
        //原公式 ：shadowAttenuation = 1 - (-shadowAttenuation + _LightArea) / _LightArea;
        shadowAttenuation /= _LightArea;
    }
    else
    { 
        shadowAttenuation = 1;
    }
    //shadowAttenuation = lerp(shadowAttenuation /= _LightArea, 1, step(_LightArea, shadowAttenuation));
    //接受投影，先这样吧，目前效果最能接受的办法了
    half3 shadowColor = _RampMap.Sample(sampler_RampMap, half2(shadowAttenuation, rampV));
    half3 lightShadowColor = _RampMap.Sample(sampler_RampMap, half2(0, rampV));
    shadowColor = lerp(lightShadowColor, shadowColor, light.shadowAttenuation);
    
#endif

    //blinnPhongSpecular
    half3 specularColor = _SpecularColor * pow(saturate(dot(inputData.normalWS, halfNormal)), _SpecularPower);
    specularColor *= surfaceData.lightMap.r;

    //return light.color * (shadowColor);
    return light.color * (shadowColor + specularColor);
}


half3 ToonSurfaceShading(ToonSurfaceData surfaceData, InputData inputData, half NdotL)
{
    // Indirect lighting
    
 #ifdef _USE_NORMALSH
     half3 Indirectlight = inputData.bakedGI * surfaceData.occlusion;
 #else
    half3 Indirectlight = ShadeGI(surfaceData);
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
    half3 directLight = DirectlightWithOutAlbedo(surfaceData, inputData, mainLight, NdotL);

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

    //return directLight * surfaceData.albedo;
    return saturate((Indirectlight + directLight) * surfaceData.albedo);
    //return CompositeAllLightResults(indirectResult, mainLightResult, additionalLightSumResult, emissionResult, surfaceData, lightingData);
}



#endif