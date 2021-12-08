Shader "SEEDzy/URP/GenerateMipMaps"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float _MainTex_TexelSize;
            CBUFFER_END

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            
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

            inline float HZBReduce(float2 inUV)
            {
                float4 depth;

                //需要采样上一级mipmap用于生成当前级的mipmap,由于长宽减半，像素量减少到原来的1/4,
                //对应的，当前mipmap一个像素值应该由之前的四个四个像素决定，
                //那么这样有如下关系，(x,y)点对应上一级(2x,2y)(2x,2y+1)(2x+1,2y)(2x+1,2y+1)四个点，
                //注意这里的点只是个点，实际上贴图是由纹素组成，纹素是有大小的，在这里，上一级纹素是当前纹素大小的
                //1/2
                //不写了，看笔记吧：https://www.notion.so/HLSL-46ec618d158c450d8ed4f728cb5631e7
                float texelSize = _MainTex_TexelSize.x;
                
                float2 uv0 = inUV + float2(-0.5f, 0.5f) * texelSize;
                float2 uv1 = inUV + float2( 0.5f, 0.5f) * texelSize;
                float2 uv2 = inUV + float2(-0.5f,-0.5f) * texelSize;
                float2 uv3 = inUV + float2(+0.5f,-0.5f) * texelSize;
                
                depth.x = _MainTex.Sample(sampler_MainTex, uv0);
                depth.y = _MainTex.Sample(sampler_MainTex, uv1);
                depth.z = _MainTex.Sample(sampler_MainTex, uv2);
                depth.w = _MainTex.Sample(sampler_MainTex, uv3);
                //在DX平台深度会翻转
#if defined(UNITY_REVERSED_Z)
                return min(min(depth.x, depth.y), min(depth.z, depth.w));
#else
                return max(max(depth.x, depth.y), max(depth.z, depth.w));
#endif
            }
            
            v2f vert (a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.texcoord;
                return o;
            }

            half4 frag (v2f i) : COLOR
            {
                // sample the texture
                half dep = HZBReduce(i.uv);
                return half4(dep, 0, 0, 1);
            }
            ENDHLSL
        }
    }
}
