#ifndef SEEDSDHADER_LIGHTING_BRDF
#define SEEDSDHADER_LIGHTING_BRDF

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

#define UNITY_INV_PI                0.31830988618f
#define F0                          half3(0.04, 0.04, 0.04)
#define SPECULARBRDF_DENOMINATOR    4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.001

Texture2D _SpecularBRDFTex;         SamplerState sampler_SpecularBRDFTex;


struct SurfaceInput
{
    half4 albedo;
    half  smoothness;
    half  metallic;
    half  occlusion;
    half3 emissionMask;
    half3 normalTS;
    half  IOR;
};


struct BRDFInput
{
    half3 f0;
    half perceptualRoughness;
    half roughness;
    half LdotV;
    half NdotL;
    half NdotV;
    half HdotV;
    half NdotH;
    //half LdotH;
};

// inline float SmoothToRoughness(float smoothness)
// {
//     float perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
//     return max(PerceptualRoughnessToRoughness(perceptualRoughness), HALF_MIN_SQRT);
// }

// Pow5 uses the same amount of instructions as generic pow(), but has 2 advantages:
// 1) better instruction pipelining
// 2) no need to worry about NaNs
inline half Pow5 (half x)
{
    return x*x * x*x * x;
}

inline half2 Pow5 (half2 x)
{
    return x*x * x*x * x;
}

inline half3 Pow5 (half3 x)
{
    return x*x * x*x * x;
}

inline half4 Pow5 (half4 x)
{
    return x*x * x*x * x;
}

// inline half3 FresnelTerm (half3 F0, half cosA)
// {
//     half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
//     return F0 + (1-F0) * t;
// }
// inline half3 FresnelLerp (half3 F0, half3 F90, half cosA)
// {
//     half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
//     return lerp (F0, F90, t);
// }
// // approximage Schlick with ^4 instead of ^5
// inline half3 FresnelLerpFast (half3 F0, half3 F90, half cosA)
// {
//     half t = Pow4 (1 - cosA);
//     return lerp (F0, F90, t);
// }

/// <summary>
/// D项
/// </summary>
float DistributionGGX(half3 N, half3 H, float roughness)
{
    float a      = roughness*roughness;
    float a2     = a*a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;

    float nom   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return nom / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float nom   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return nom / denom;
}
/// <summary>
/// G项
/// </summary>
float GeometrySmith(half3 N, half3 V, half3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

/// <summary>
/// HDRP的DV项,v项是G项和brdf分母的组合
/// </summary>
// Inline D_GGX() * V_SmithJointGGX() together for better code generation.
real DV_SmithJointGGX_HDRP(real NdotH, real NdotL, real NdotV, real roughness)
{
    real a2 = Sq(roughness);

    real partLambdaV = sqrt((-NdotV * a2 + NdotV) * NdotV + a2);
    
    real s = (NdotH * a2 - NdotH) * NdotH + 1.0;

    real lambdaV = NdotL * partLambdaV;
    real lambdaL = NdotV * sqrt((-NdotL * a2 + NdotL) * NdotL + a2);

    real2 D = real2(a2, s * s);            // Fraction without the multiplier (1/Pi)
    real2 G = real2(1, lambdaV + lambdaL); // Fraction without the multiplier (1/2)

    // This function is only used for direct lighting.
    // If roughness is 0, the probability of hitting a punctual or directional light is also 0.
    // Therefore, we return 0. The most efficient way to do it is with a max().
    return INV_PI * 0.5 * (D.x * G.x) / max(D.y * G.y, REAL_MIN);
}

/// <summary>
/// metallic相关F0
/// </summary>
inline half3 GetF0(half3 albedo, half metallic)
{
    return lerp(F0, albedo, metallic);
}

/// <summary>
/// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
/// </summary>
inline half3 FresnelTerm_Schlick(float HdotV, half3 f0)
{
    return f0 + (1.0 - f0) * Pow5(1.0 - HdotV);
}
/// <summary>
/// UE加速版Fresnel
/// </summary>
inline half3 FresnelTerm_UE(float HdotV, half3 f0)
{
    return f0 + (1 - f0) * pow(2, (-5.55473 * HdotV - 6.98316) * HdotV);
}

/// <summary>
/// 混入粗糙度因子的F项，主要在间接光使用
/// </summary>
inline half3 FresnelSchlickRoughness(float HdotV, half3 f0, float roughness)
{
    return f0 + (max((1.0 - roughness).rrr, f0) - f0) * Pow5(1.0 - HdotV);
}

inline float GGXTerm (float NdotH, float roughness)
{
    float a2 = roughness * roughness;
    float d = (NdotH * a2 - NdotH) * NdotH + 1.0f; 
    return UNITY_INV_PI * a2 / (d * d + 1e-7f); 
}

half DisneyDiffuse(half NdotV, half NdotL, half LdotV, half perceptualRoughness)
{
    // (2 * LdotH * LdotH) = 1 + LdotV
    // real fd90 = 0.5 + (2 * LdotH * LdotH) * perceptualRoughness;
    real fd90 = 0.5 + (perceptualRoughness + perceptualRoughness * LdotV);
    // Two schlick fresnel term
    half lightScatter   = (1 + (fd90 - 1) * Pow5(1 - NdotL));
    half viewScatter    = (1 + (fd90 - 1) * Pow5(1 - NdotV));
    // half lightScatter   = 1 - FresnelTerm_UE(fd90, NdotL);
    // half viewScatter    = 1 - FresnelTerm_UE(fd90, NdotV);
    return lightScatter * viewScatter * UNITY_INV_PI;
}

/// <summary>
/// 采样SpecularBRDF Lut
/// </summary>
half2 BRDF_Specular_Lut(half NdotV, half roughness)
{
    //这里不lerp效果有点奇葩啊，粗糙度最大时90度视角会有个黑圈
    return _SpecularBRDFTex.Sample(sampler_SpecularBRDFTex, half2(lerp(0, 0.99, NdotV), lerp(0, 0.99, roughness))).rg;
}


#endif