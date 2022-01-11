#ifndef SEED_LIT_FORWARD_INCLUDED
#define SEED_LIT_FORWARD_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "CustomUVTextureDeclare.hlsl"


struct a2v
{
    float4 positionOS : POSITION;
    float2 texcoord : TEXCOORD0;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    float4 positionCS : SV_POSITION;
};


void InitVertInputData(v2f i, out InputData o)
{
    o = (InputData)0;
    
}



v2f vert (a2v i)
{
    v2f o;
    o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
    o.uv = TRANSFORM_TEX(i.texcoord, _BaseMap);
    return o;
}

half4 frag (v2f i) : COLOR
{
    // sample the texture
    half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
    return col;
}


#endif