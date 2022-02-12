#ifndef TOON_INPUT_DATA
#define TOON_INPUT_DATA

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "ToonSurfaceData.hlsl"

#define SKIN_RAMP_LAYER 1

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

    //specular
    half    _SpecPower ;
    half    _SpecPower2;
    half    _SpecPower3;
    half    _SpecPower4;
    half    _SpecPower5;
    half3   _SpecColor;
    half    _SpecColorMulti ;
    half    _SpecColorMulti2;
    half    _SpecColorMulti3;
    half    _SpecColorMulti4;
    half    _SpecColorMulti5;

    // lighting
    half3   _IndirectLightMinColor;
    half    _CelShadeMidPoint;
    half    _CelShadeSoftness;
    half    _LightArea;
    half4   _RampMapLayerSwitch;
    half    _UseVertexRampWidth;
    half    _ColorTone;
    half    _LightRatio;
    half    _EmissionPower;

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
    output.emission = _EmissionPower;
    output.occlusion = 1;
    output.lightMap = lightMap;
    output.vertexColor = vertexColor;
}


/// <summary>
/// 这逻辑。。。。晕
/// </summary>
half GetYSRampMapLayer(half rampMask)
{
    half4 condition1 = rampMask.xxxx >= half4(0.80, 0.60, 0.40, 0.20);
    half3 condition2  = rampMask.xxx     <     half3(0.80, 0.60, 0.40);
    
    half finalLayer = lerp(1         , 2, condition1.x                * _RampMapLayerSwitch.x);
    finalLayer      = lerp(finalLayer, 5, condition1.y * condition2.x * _RampMapLayerSwitch.y);
    finalLayer      = lerp(finalLayer, 3, condition1.z * condition2.y * _RampMapLayerSwitch.z);
    finalLayer      = lerp(finalLayer, 4, condition1.w * condition2.z * _RampMapLayerSwitch.w);

    return finalLayer;
}

half4 GetYSSpecColorPower(half finalLayer)
{
    half4 condition = finalLayer.xxxx == half4(2.0, 3.0, 4.0, 1.0);
    half specPower = lerp(_SpecPower5, _SpecPower4, condition.z);
    specPower      = lerp( specPower,  _SpecPower3, condition.y);
    specPower      = lerp( specPower,  _SpecPower2, condition.x);
    specPower      = lerp( specPower,  _SpecPower,  condition.w);

    half specMulti = lerp(_SpecColorMulti5, _SpecColorMulti4, condition.z);
    specMulti      = lerp(specMulti,        _SpecColorMulti3, condition.y);
    specMulti      = lerp(specMulti,        _SpecColorMulti2, condition.x);
    specMulti      = lerp(specMulti,        _SpecColorMulti,  condition.w);
    
    return half4(specMulti.xxx * _SpecColor, specPower);
}

void InitializeYSData(half rampMask, out half2 rampV, out half4 specColorPower)
{
    half rampLayer = 0;
#ifdef _USE_RAMPMAP
    #ifdef _ISFACE
    rampLayer = GetYSRampMapLayer(SKIN_RAMP_LAYER);
    #else
    rampLayer = GetYSRampMapLayer(rampMask);
    #endif
#endif

    //逻辑还算简单，-1是为了把坐标起点映射到0
    //*0.1是为了把坐标缩放到0 ~ 1
    //+0.05是为了是采样点位于ramp中部
    //1-其实是因为uv和ramp顺序是反的，也可以直接反转纹理
    rampV.x = 1 - ((rampLayer - 1) * 0.1 + 0.05);
    rampV.y = 1 - ((rampLayer - 1) * 0.1 + 0.55);

    specColorPower = GetYSSpecColorPower(rampLayer);
}

#endif