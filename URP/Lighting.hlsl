#ifndef SEEDzy_Lighting
#define SEEDzy_Lighting
// #pragma once is a safe guard best practice in almost every .hlsl (need Unity2020 or up), 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#pragma once

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "BRDF/BRDF.hlsl"

#define F0 half4(0.04, 0.04, 0.04, 1.0 - 0.04)


/// <summary>
/// 表面光照需要的数据，务必归一化
/// </summary>
struct SurfaceLightData
{
    half3 normalWS;
    half3 viewDirWS;
    //float3 positionWS;
    half3 albedo;

    half3 lightDirWS;
    half3 lightColor;
    
};

/// <summary>
/// 获得blinphong高光...终于发现BP有个严重缺陷，背光处会透光
/// </summary>
half3 GetBlinPhongLight(SurfaceLightData i, float gloss, half3 color)
{
    half3 halfNomral = normalize(i.viewDirWS + i.lightDirWS);
    half3 specular = i.lightColor * pow(saturate(dot(i.normalWS, halfNomral)), gloss) * color;
    return specular;
}

/// <summary>
/// 获得phong高光
/// </summary>
half3 GetPhongLight(SurfaceLightData i, float gloss, half3 color)
{
    half3 reflectLightDir = normalize(reflect(-i.lightDirWS, i.normalWS));
    half3 specular = i.lightColor * pow(saturate(dot(reflectLightDir, i.viewDirWS)), gloss) * color;
    return specular;
}

/// <summary>
/// 获得halfLambert漫反射
/// </summary>
half3 GetHLambertLight(in SurfaceLightData i, half3 diffuseColor)
{
    half3 diffuse = i.albedo * (0.5 * dot(i.normalWS, i.lightDirWS) + 0.5) * diffuseColor * i.lightColor;
    return diffuse;
}

/// <summary>
/// BlackOps2拟合的环境光照高光BRDF
/// </summary>
float3 EnvironmentBRDF_BlackOps2Approximation(float g, float NoV, float3 rf0)
{
    float4 t = float4(1 / 0.96, 0.475, (0.0275 - 0.25 * 0.04) / 0.96, 0.25);
    t *= float4(g, g, g, g);
    t += float4(0, 0, (0.015 - 0.75 * 0.04) / 0.96, 0.75);
    float a0 = t.x * min(t.y, exp2(-9.28 * NoV)) + t.z;
    float a1 = t.w;
    return saturate(lerp(a0, a1, rf0));
}

/// <summary>
/// 计算间接光照(Specular通过BRDF Lut计算，此处BRDF不是完整公式，只包含specularTerm)
/// 再次注意!!最终进入摄像机的光照能量等于原始光线辐照度 * BRDF
/// </summary>
half3 IndirectLight_Lut(BRDFData brdfData,half3 bakedGI, half occlusion,
    half3 normalWS, half3 viewDirectionWS)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half NoV = saturate(dot(normalWS, viewDirectionWS));
    half3 fresnelTerm = FresnelSchlickRoughness(NoV, F0, brdfData.perceptualRoughness);

    half3 irradianceDiffuse = bakedGI * occlusion;
    half3 irradianceSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion);

    /////////////////////////////间接光照BRDF
    //Indirect diffuse的颜色计算
    half3 color = irradianceDiffuse * brdfData.diffuse;
    //Indirect Specular的颜色计算
    half2 specBrdf = BRDF_Specular_Lut(NoV, brdfData.perceptualRoughness);
    color += irradianceSpecular * half3(fresnelTerm * specBrdf.x + specBrdf.y);

    return color;
}

/// <summary>
/// 使用Lut采样高光的PBR光照
/// </summary>
half4 PBR_Lut(InputData inputData, SurfaceData surfaceData)
{
#ifdef _SPECULARHIGHLIGHTS_OFF
    bool specularHighlightsOff = true;
#else
    bool specularHighlightsOff = false;
#endif

    BRDFData brdfData;

    // NOTE: can modify alpha
    InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

    BRDFData brdfDataClearCoat = (BRDFData)0;

    // To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
#if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
    half4 shadowMask = inputData.shadowMask;
#elif !defined (LIGHTMAP_ON)
    half4 shadowMask = unity_ProbesOcclusion;
#else
    half4 shadowMask = half4(1, 1, 1, 1);
#endif

    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);

    #if defined(_SCREEN_SPACE_OCCLUSION)
        AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
        mainLight.color *= aoFactor.directAmbientOcclusion;
        surfaceData.occlusion = min(surfaceData.occlusion, aoFactor.indirectAmbientOcclusion);
    #endif

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);
    half3 color = IndirectLight_Lut(brdfData, inputData.bakedGI, surfaceData.occlusion,
                                     inputData.normalWS, inputData.viewDirectionWS);
    color += LightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                     mainLight,
                                     inputData.normalWS, inputData.viewDirectionWS,
                                     surfaceData.clearCoatMask, specularHighlightsOff);

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
        #if defined(_SCREEN_SPACE_OCCLUSION)
            light.color *= aoFactor.directAmbientOcclusion;
        #endif
        color += LightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                         light,
                                         inputData.normalWS, inputData.viewDirectionWS,
                                         surfaceData.clearCoatMask, specularHighlightsOff);
    }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    color += inputData.vertexLighting * brdfData.diffuse;
#endif

    color += surfaceData.emission;

    return half4(color, surfaceData.alpha);
}

#endif
