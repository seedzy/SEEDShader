#ifndef SEED_Stylized_LIT_PASS_INCLUDED
#define SEED_Stylized_LIT_PASS_INCLUDED

#include "Assets/Shader/SEEDShader/ShaderLibrary/SEED_Lighting.hlsl"
#include "Assets/Shader/SEEDShader/ShaderLibrary/Common.hlsl"

struct a2v
{
    float4 positionOS : POSITION;
    float3 normalOS   : NORMAL;
    float2 texcoord   : TEXCOORD0;
#ifdef _NORMALMAP
    float4 tangent    : TANGENT;
#endif
};

struct v2f
{
    float2 uv         : TEXCOORD0;
    float4 positionCS : SV_POSITION;
    float3 positionWS : TEXCOORD1;
    half3  normalWS   : TEXCOORD2;
    half3  viewDirWS  : TEXCOORD3;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 4);
#ifdef _NORMALMAP
    float4 tangentWS : TEXCOORD5;
#endif
};


void InitInputData(v2f i, out InputData o, half3 normalTS)
{
    o = (InputData)0;

    half4 zero = (half4)0;

    o.positionWS              = i.positionWS;
#ifdef _NORMALMAP
    float sgn = i.tangentWS.w;      // should be either +1 or -1
    float3 bitangent = sgn * cross(i.normalWS.xyz, i.tangentWS.xyz);
    o.normalWS = TransformTangentToWorld(normalTS, half3x3(i.tangentWS.xyz, bitangent.xyz, i.normalWS.xyz));
#else
    o.normalWS                = normalize(i.normalWS);
#endif
    o.viewDirectionWS         = normalize(i.viewDirWS);
    o.shadowCoord             = zero;
    o.fogCoord                = zero.r;
    o.vertexLighting          = zero.rgb;
    o.bakedGI                 = SampleSH(i.normalWS);//SAMPLE_GI(i.lightmapUV, i.vertexSH, i.normalWS);
    o.normalizedScreenSpaceUV = zero.rg;
    o.shadowMask              = zero;
    
}



v2f vert (a2v i)
{
    v2f o;
    o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
    o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
#ifdef _NORMALMAP
    o.tangentWS  = float4(TransformObjectToWorldDir(i.tangent.xyz), i.tangent.w * GetOddNegativeScale());
#endif
    o.normalWS   = TransformObjectToWorldNormal(i.normalOS);
    o.viewDirWS  = GetWorldSpaceViewDir(o.positionWS);
    o.uv = TRANSFORM_TEX(i.texcoord, _BaseMap);
    return o;
}

half4 frag (v2f i) : COLOR
{
    SurfaceInput surfaceInput;
    InitLitSurfaceData(i.uv, surfaceInput);

    InputData inputData;
    InitInputData(i, inputData, surfaceInput.normalTS);
    
    Light light = GetMainLight();

    half3 lightDirectionWS = normalize(light.direction);
    ////////////////////
    half NdotL = dot(inputData.normalWS, lightDirectionWS);
    half radiance = 0.5 * NdotL + 0.5;
    radiance = LinearStep(_DarkAreasThreshold - _DarkAreasSmooth, _DarkAreasThreshold + _DarkAreasSmooth, radiance);
    //difuse和specular的albedo分开处理，不然风格化会有问题,。。。。。没事了
    surfaceInput.albedo.rgb = lerp(_DarkAreasColor * surfaceInput.albedo.rgb, surfaceInput.albedo.rgb, radiance);
    /////////////////////////
    BRDFInput brdfInput;
    InitBRDFInput(inputData, surfaceInput, lightDirectionWS, brdfInput);

    half3 ks = FresnelTerm_UE(brdfInput.HdotV, brdfInput.f0);
    half3 kd = (1 - brdfInput.f0) * (1 - surfaceInput.metallic);
    
    half3 diffuseTerm  =kd * DisneyDiffuse(brdfInput.NdotV, brdfInput.NdotL, brdfInput.LdotV, brdfInput.perceptualRoughness) * surfaceInput.albedo.rgb;;
    half spevularBRDF = DV_SmithJointGGX_HDRP(brdfInput.NdotH, brdfInput.NdotL, brdfInput.NdotV, brdfInput.roughness);

    half3 spevularTerm = ks *  LinearStep(_SpecularThreshold - _SpecularSmooth, _SpecularThreshold + _SpecularSmooth, spevularBRDF) * _SpecularStrength;
    
    half3 color = diffuseTerm + spevularTerm * saturate(NdotL);
    color *= light.color;
    //URP包括Builtin都没除pi，为了保持亮度，这里先加回去
    color *= PI;
    
    color += IndirectLight(inputData, surfaceInput, brdfInput);

    color += surfaceInput.emissionMask * surfaceInput.albedo.rgb;
    
    return half4(color, 1);
}


#endif