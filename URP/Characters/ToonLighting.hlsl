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

half3 DirectlightWithOutAlbedo(ToonSurfaceData surfaceData, InputData inputData, Light light)
{
    half NdotL = dot(inputData.normalWS, light.direction);
    half3 halfNormal = normalize(light.direction + inputData.viewDirectionWS);

    
#ifndef _USE_GRADIENTMAP 
    half litOrShadowMark = smoothstep(_CelShadeMidPoint-_CelShadeSoftness,_CelShadeMidPoint+_CelShadeSoftness, NdotL);
    // light's shadow map
    litOrShadowMark *= lerp(1,light.shadowAttenuation,_ReceiveShadowMappingAmount);
    //shadow Color
    half3 shadowColor = lerp(_ShadowMapColor,1, litOrShadowMark);

    half distanceAttenuation = min(4,light.distanceAttenuation);
    shadowColor *= light.distanceAttenuation;
#else
    
#endif
    //lambertDiffuse
    

    //blinnPhongSpecular
    half3 specularColor = _SpecularColor * pow(saturate(dot(inputData.normalWS, halfNormal)), _SpecularPower);
    specularColor *= surfaceData.specularMask;

    return light.color * (shadowColor + specularColor);
}


half3 ToonSurfaceShading(ToonSurfaceData surfaceData, InputData inputData)
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
    half3 directLight = DirectlightWithOutAlbedo(surfaceData, inputData, mainLight);

    //==============================================================================================
    // All additional lights

    half3 additionalLightSumResult = 0;

#ifdef _ADDITIONAL_LIGHTS
    // Returns the amount of lights affecting the object being renderer.
    // These lights are culled per-object in the forward renderer of URP.
    int additionalLightsCount = GetAdditionalLightsCount();
    for (int i = 0; i < additionalLightsCount; ++i)
    {
        // Similar to GetMainLight(), but it takes a for-loop index. This figures out the
        // per-object light index and samples the light buffer accordingly to initialized the
        // Light struct. If ADDITIONAL_LIGHT_CALCULATE_SHADOWS is defined it will also compute shadows.
        int perObjectLightIndex = GetPerObjectLightIndex(i);
        Light light = GetAdditionalPerObjectLight(perObjectLightIndex, lightingData.positionWS); // use original positionWS for lighting
        light.shadowAttenuation = AdditionalLightRealtimeShadow(perObjectLightIndex, shadowTestPosWS); // use offseted positionWS for shadow test

        // Different function used to shade additional lights.
        additionalLightSumResult += ShadeSingleLight(surfaceData, lightingData, light, true);
    }
#endif
    //==============================================================================================

    // emission
    //half3 emissionResult = ShadeEmission(surfaceData, lightingData);

    //return directLight * surfaceData.albedo;
    return (Indirectlight + directLight) * surfaceData.albedo;
    //return CompositeAllLightResults(indirectResult, mainLightResult, additionalLightSumResult, emissionResult, surfaceData, lightingData);
}



#endif