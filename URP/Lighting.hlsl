#ifndef SEEDzy_Lighting
#define SEEDzy_Lighting
// #pragma once is a safe guard best practice in almost every .hlsl (need Unity2020 or up), 
// doing this can make sure your .hlsl's user can include this .hlsl anywhere anytime without producing any multi include conflict
#pragma once

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

/// <summary>
/// 表面光照需要的数据，务必归一化
/// </summary>
struct SurfaceLightData
{
    half3 normalWS;
    half3 viewDirWS;
    float3 positionWS;
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
half3 GetHLambertLight(SurfaceLightData i, half3 color)
{
    half3 diffuse = i.albedo * (0.5 * dot(i.normalWS, i.lightDirWS) + 0.5) * color;
    return diffuse;
}

//世界空间转切线空间
#define TANGENT_SPACE_ROTATION \
float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) ) * v.tangent.w; \
float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal )


#endif
