#ifndef SEED_STYLIZED_LIT_INPUTDATA_INIT_INCLUDED
#define SEED_STYLIZED_LIT_INPUTDATA_INIT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Assets/Shader/SEEDShader/ShaderLibrary/BRDF.hlsl"
#include "LitUniversalCBuffer.hlsl"
    
CBUFFER_START(UnityPerMaterial)
LIT_UNIVERSAL_CBUFFER
half3 _DarkAreasColor;
half _DarkAreasSmooth;
half _DarkAreasThreshold;
half _SpecularThreshold;
half _SpecularSmooth;
half _SpecularStrength;
CBUFFER_END

TEXTURE2D(_BaseMap);      SAMPLER(sampler_BaseMap); 
TEXTURE2D(_Smoe);         SAMPLER(sampler_Smoe); 
TEXTURE2D(_BumpMap);         SAMPLER(sampler_BumpMap); 


half3 SampleNormal(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), half scale = 1.0h)
{
    #ifdef _NORMALMAP
    half4 n = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
    #if BUMP_SCALE_NOT_SUPPORTED
    return UnpackNormal(n);
    #else
    return UnpackNormalScale(n, scale);
    #endif
    #else
    return half3(0.0h, 0.0h, 1.0h);
    #endif
}


inline void InitLitSurfaceData(float2 uv, out SurfaceInput outSurfaceInput)
{
    half4 albedo  = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv) * _Albedo;
    half4 mixData = half4(1,1,0,1);
    
    #ifdef _MIXMAP_ON
    mixData = SAMPLE_TEXTURE2D(_Smoe, sampler_Smoe, uv);
    #endif

    outSurfaceInput.albedo       = albedo;
    outSurfaceInput.smoothness   = mixData.r * _Smoothness;
    outSurfaceInput.metallic     = mixData.g * _Metallic;
    outSurfaceInput.occlusion    = (1 - mixData.b) * _Occlusion;
    outSurfaceInput.emissionMask = mixData.a * _Emission * _EmissionColor;
    outSurfaceInput.normalTS     = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
}



#endif