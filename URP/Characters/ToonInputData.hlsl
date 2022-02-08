#ifndef TOON_INPUT_DATA
#define TOON_INPUT_DATA

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "ToonSurfaceData.hlsl"
// put all your uniforms(usually things inside .shader file's properties{}) inside this CBUFFER, in order to make SRP batcher compatible
// see -> https://blogs.unity3d.com/2019/02/28/srp-batcher-speed-up-your-rendering/
CBUFFER_START(UnityPerMaterial)
    
    // high level settings
    float   _IsFace;

    // base color
    float4  _BaseMap_ST;
    half4   _BaseColor;

    // alpha
    half    _Cutoff;

    // emission
    float   _UseEmission;
    half3   _EmissionColor;
    half    _EmissionMulByBaseColor;
    half3   _EmissionMapChannelMask;

    // occlusion
    float   _UseOcclusion;
    half    _OcclusionStrength;
    half4   _OcclusionMapChannelMask;
    half    _OcclusionRemapStart;
    half    _OcclusionRemapEnd;

    //specularMask
    float   _UseSpecularMask;
    float   _SpecularPower;
    half3   _SpecularColor;
    half3   _SpecularMapChannelMask;

    // lighting
    half3   _IndirectLightMinColor;
    half    _CelShadeMidPoint;
    half    _CelShadeSoftness;
    half    _LightArea;
    half4   _RampMapLayerSwitch;
    half    _UseVertexRampWidth;

    // shadow mapping
    half    _ReceiveShadowMappingAmount;
    float   _ReceiveShadowMappingPosOffset;
    half3   _ShadowMapColor;

    // outline
    float   _OutlineWidth;
    half3   _OutlineColor;
    float   _OutlineZOffset;
    float   _OutlineZOffsetMaskRemapStart;
    float   _OutlineZOffsetMaskRemapEnd;

CBUFFER_END


TEXTURE2D(_BaseMap);  SAMPLER(sampler_BaseMap);
TEXTURE2D(_RampMap);  SAMPLER(sampler_RampMap);
TEXTURE2D(_LightMap); SAMPLER(sampler_LightMap);

sampler2D _EmissionMap;
sampler2D _OcclusionMap;
sampler2D _SpecularMap;
sampler2D _OutlineZOffsetMaskTex;

//a special uniform for applyShadowBiasFixToHClipPos() only, it is not a per material uniform, 
//so it is fine to write it outside our UnityPerMaterial CBUFFER
float3 _LightDirection;


void AlphaTest(half alpha) 
{
    #if _ALPHATEST_ON
    clip(alpha - _Cutoff);
    #endif
}

/// <summary>
/// 初始化表面数据
/// </summary>
void InitializeSurfaceData(float2 uv, half4 vertexColor, out ToonSurfaceData output)
{
    // albedo & alpha
    float4 baseColor = _BaseMap.Sample(sampler_BaseMap, uv);

    AlphaTest(baseColor.a);// early exit if possible

    half4 lightMap = _LightMap.Sample(sampler_LightMap, uv);
    // // emission
    // output.emission = GetFinalEmissionColor(input);
    //
    // // occlusion
    // output.occlusion = GetFinalOcculsion(input);
    //
    // //specularMask
    // output.specularMask = GetSpecularMask(input);
    
    output.albedo = baseColor.rgb;
    output.alpha = baseColor.a;
    output.emission = half3(0,0,0);
    output.occlusion = 1;
    output.lightMap = lightMap;
    output.vertexColor = vertexColor;
}

#endif