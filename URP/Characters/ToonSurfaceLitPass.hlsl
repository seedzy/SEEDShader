 #ifndef TOON_SURFACE_LIT_PASS
#define TOON_SURFACE_LIT_PASS

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// #include "NiloOutlineUtil.hlsl"
// #include "NiloZOffset.hlsl"
// #include "NiloInvLerpRemap.hlsl"

#include "ToonInputData.hlsl"
#include "ToonLighting.hlsl"

struct a2v
{
    float3 positionOS   : POSITION;
    half3 normalOS      : NORMAL;
    half4 tangentOS     : TANGENT;
    half4 vertexColor   : COLOR;
    float2 uv           : TEXCOORD0;
};

// all pass will share this Varyings struct (define data needed from our vertex shader to our fragment shader)
struct v2f
{
    float2 uv                       : TEXCOORD0;
    float4 positionWSWithNdotL      : TEXCOORD1; // xyz: positionWS, w: vertex fog factor
    half3 normalWS                  : TEXCOORD2;
    half4 fogFactorAndVertexLight   : TEXCOORD3;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 4);
    half4 vertexColor               : TEXCOORD5;
    float4 positionCS               : SV_POSITION;
};




///////////////////////////////////////////////////////////////////////////////////////
// vertex shared functions
///////////////////////////////////////////////////////////////////////////////////////

// /// <summary>
// /// 将顶点沿着表面法线方向扩张
// /// </summary>
// float3 TransformPositionWSToOutlinePositionWS(float3 positionWS, float positionVS_Z, float3 normalWS)
// {
//     //you can replace it to your own method! Here we will write a simple world space method for tutorial reason, it is not the best method!
//     //这里修正轮廓线宽度
//     float outlineExpandAmount = _OutlineWidth * GetOutlineCameraFovAndDistanceFixMultiplier(positionVS_Z);
//     return positionWS + normalWS * outlineExpandAmount; 
// }



void InitializeInputData(v2f input, out InputData inputData)
{
    inputData = (InputData)0;

    inputData.positionWS = input.positionWSWithNdotL.xyz;

    inputData.viewDirectionWS = SafeNormalize(_WorldSpaceCameraPos - input.positionWSWithNdotL.xyz);
    #if defined(_NORMALMAP) || defined(_DETAIL)
    float sgn = input.tangentWS.w;      // should be either +1 or -1
    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
    #else
    inputData.normalWS = input.normalWS;
    #endif

    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    inputData.shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

    inputData.fogCoord = input.fogFactorAndVertexLight.x;
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
    //inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
}

// if "ToonShaderIsOutline" is not defined    = do regular MVP transform
// if "ToonShaderIsOutline" is defined        = do regular MVP transform + push vertex out a bit according to normal direction
v2f VertexShaderWork(a2v input)
{
    v2f output;

    // VertexPositionInputs contains position in multiple spaces (world, view, homogeneous clip space, ndc)
    // Unity compiler will strip all unused references (say you don't use view space).
    // Therefore there is more flexibility at no additional cost with this struct.
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);

    // Similar to VertexPositionInputs, VertexNormalInputs will contain normal, tangent and bitangent
    // in world space. If not used it will be stripped.
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    float3 positionWS = vertexInput.positionWS;

//     外扩法线
// #ifdef ToonShaderIsOutline
//     //试一下压扁法线的效果
//     float3 outLineNormal = TransformObjectToWorldNormal(float3(input.normalOS.xy, input.normalOS.z * 0.1));
//     //ToDo临时用tangent存一下平滑法线，后面在改
//     positionWS = TransformPositionWSToOutlinePositionWS(vertexInput.positionWS, vertexInput.positionVS.z, vertexNormalInput.tangentWS);
// #endif
    // Computes fog factor per-vertex.
    half3 vertexLight = VertexLighting(vertexInput.positionWS, vertexNormalInput.normalWS);
    half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

    float NdotL = dot(vertexNormalInput.normalWS, GetMainLight().direction) * 0.5 + 0.5;

    // TRANSFORM_TEX is the same as the old shader library.
    output.uv = TRANSFORM_TEX(input.uv,_BaseMap);
    //问就是省
    output.positionWSWithNdotL = float4(positionWS, NdotL);

    // packing positionWS(xyz) & fog(w) into a vector4
    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
    output.normalWS = vertexNormalInput.normalWS; //normlaized already by GetVertexNormalInputs(...)
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    output.positionCS = TransformWorldToHClip(positionWS);

    output.vertexColor = input.vertexColor;

// #ifdef ToonShaderIsOutline
//     // [Read ZOffset mask texture]
//     // we can't use tex2D() in vertex shader because ddx & ddy is unknown before rasterization, 
//     // so use tex2Dlod() with an explict mip level 0, put explict mip level 0 inside the 4th component of param uv)
//     float outlineZOffsetMaskTexExplictMipLevel = 0;
//     float outlineZOffsetMask = tex2Dlod(_OutlineZOffsetMaskTex, float4(input.uv,0,outlineZOffsetMaskTexExplictMipLevel)).r; //we assume it is a Black/White texture
//
//     // [Remap ZOffset texture value]
//     // flip texture read value so default black area = apply ZOffset, because usually outline mask texture are using this format(black = hide outline)
//     outlineZOffsetMask = 1-outlineZOffsetMask;
//     outlineZOffsetMask = invLerpClamp(_OutlineZOffsetMaskRemapStart,_OutlineZOffsetMaskRemapEnd,outlineZOffsetMask);// allow user to flip value or remap
//
//     // [Apply ZOffset, Use remapped value as ZOffset mask]
//     output.positionCS = NiloGetNewClipPosWithZOffset(output.positionCS, _OutlineZOffset * outlineZOffsetMask + 0.03 * _IsFace);
// #endif

    // ShadowCaster pass needs special process to positionCS, else shadow artifact will appear
    //--------------------------------------------------------------------------------------
// #ifdef ToonShaderApplyShadowBiasFix
//     // see GetShadowPositionHClip() in URP/Shaders/ShadowCasterPass.hlsl
//     // https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl
//     float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, output.normalWS, _LightDirection));
//
//     #if UNITY_REVERSED_Z
//     positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
//     #else
//     positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
//     #endif
//     output.positionCS = positionCS;
// #endif
    //--------------------------------------------------------------------------------------    

    return output;
}

///////////////////////////////////////////////////////////////////////////////////////
// fragment shared functions (Step1: prepare data structs for lighting calculation)
///////////////////////////////////////////////////////////////////////////////////////
/// <summary>
/// 采样baseMap颜色
/// </summary>
// half4 GetFinalBaseColor(v2f input)
// {
//     return tex2D(_BaseMap, input.uv) * _BaseColor;
// }

/// <summary>
/// 采样EmissionMap颜色
/// </summary>
half3 GetFinalEmissionColor(v2f input)
{
    half3 result = 0;
    if(_UseEmission)
    {
        result = tex2D(_EmissionMap, input.uv).rgb * _EmissionMapChannelMask * _EmissionColor.rgb;
    }

    return result;
}

/// <summary>
/// 采样OcclusionMap颜色,这个贴图主要是为了做出环境光遮蔽的效果
/// </summary>
// half GetFinalOcculsion(v2f input)
// {
//     half result = 1;
//     if(_UseOcclusion)
//     {
//         half4 texValue = tex2D(_OcclusionMap, input.uv);
//         //指定mask使用的通道
//         half occlusionValue = dot(texValue, _OcclusionMapChannelMask);
//         occlusionValue = lerp(1, occlusionValue, _OcclusionStrength);
//         occlusionValue = invLerpClamp(_OcclusionRemapStart, _OcclusionRemapEnd, occlusionValue);
//         result = occlusionValue;
//     }
//
//     return result;
// }

/// <summary>
/// 采样SpecularMask,这个贴图主要是为了限制高光区域
/// </summary>
half GetSpecularMask(v2f input)
{
    half result = 1;
    if(_UseSpecularMask)
    {
        half4 texValue = tex2D(_SpecularMap, input.uv);
        //指定mask使用的通道
        half specularMaskValue = dot(texValue.xyz, _SpecularMapChannelMask);
        
        result = specularMaskValue;
    }
    //采样并直接返回了，之后再改
    return result;
}


half3 ConvertSurfaceColorToOutlineColor(half3 originalSurfaceColor)
{
    return originalSurfaceColor * _OutlineColor;
}
// half3 ApplyFog(half3 color, v2f input)
// {
//     half fogFactor = input.positionWSAndFogFactor.w;
//     // Mix the pixel color with fogColor. You can optionaly use MixFogColor to override the fogColor
//     // with a custom one.
//     color = MixFog(color, fogFactor);
//
//     return color;  
// }

// only the .shader file will call this function by 
// #pragma fragment ShadeFinalColor
half4 ShadeFinalColor(v2f input) : SV_TARGET
{

    ToonSurfaceData surfaceData;
    InitializeSurfaceData(input.uv, input.vertexColor, surfaceData);
    
    InputData inputData;
    InitializeInputData(input, inputData);
    
    half3 finColor = ToonSurfaceShading(surfaceData, inputData, input.positionWSWithNdotL.w);


    //混合描边和贴图颜色
#ifdef ToonShaderIsOutline
    finColor = ConvertSurfaceColorToOutlineColor(finColor);
#endif

    return (half4)surfaceData.lightMap.g;
    //finColor = ApplyFog(finColor, input);
    return half4(finColor, surfaceData.alpha);
}

//////////////////////////////////////////////////////////////////////////////////////////
// fragment shared functions (for ShadowCaster pass & DepthOnly pass to use only)
//////////////////////////////////////////////////////////////////////////////////////////
// void BaseColorAlphaClipTest(v2f input)
// {
//     AlphaTest(GetFinalBaseColor(input).a);
// }



#endif