#ifndef SEEDSDHADER_LIGHTING_BRDF
#define SEEDSDHADER_LIGHTING_BRDF


#define UNITY_INV_PI        0.31830988618f

Texture2D _SpecularBRDFTex;         SamplerState sampler_SpecularBRDFTex;


inline float SmoothToRoughness(float smoothness)
{
    float perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
    return max(PerceptualRoughnessToRoughness(perceptualRoughness), HALF_MIN_SQRT);
}

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

inline half3 FresnelTerm (half3 F0, half cosA)
{
    half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
    return F0 + (1-F0) * t;
}
inline half3 FresnelLerp (half3 F0, half3 F90, half cosA)
{
    half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
    return lerp (F0, F90, t);
}
// approximage Schlick with ^4 instead of ^5
inline half3 FresnelLerpFast (half3 F0, half3 F90, half cosA)
{
    half t = Pow4 (1 - cosA);
    return lerp (F0, F90, t);
}

/// <summary>
/// 混入粗糙度因子的F项，主要在间接光使用
/// </summary>
inline half3 FresnelSchlickRoughness(float cosTheta, half3 F0, float roughness)
{
    return F0 + (max((1.0 - roughness).rrr, F0) - F0) * Pow5(1.0 - cosTheta);
}

inline float GGXTerm (float NdotH, float roughness)
{
    float a2 = roughness * roughness;
    float d = (NdotH * a2 - NdotH) * NdotH + 1.0f; 
    return UNITY_INV_PI * a2 / (d * d + 1e-7f); 
}

half DisneyDiffuse(half NdotV, half NdotL, half LdotH, half perceptualRoughness)
{
    half fd90 = 0.5 + 2 * LdotH * LdotH * perceptualRoughness;
    // Two schlick fresnel term
    half lightScatter   = (1 + (fd90 - 1) * Pow5(1 - NdotL));
    half viewScatter    = (1 + (fd90 - 1) * Pow5(1 - NdotV));
    return lightScatter * viewScatter;
}

/// <summary>
/// 采样SpecularBRDF Lut
/// </summary>
half2 BRDF_Specular_Lut(half NdotV, half roughness)
{
    return _SpecularBRDFTex.Sample(sampler_SpecularBRDFTex, half2(NdotV, roughness)).rg;
}

#endif