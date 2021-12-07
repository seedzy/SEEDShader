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
            float4 _MainTex_ST;
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

            inline float HZBReduce(sampler2D  mainTex, float2 inUV)
            {
                float4 depth;
                // float2 uv0 = inUV + float2(-0.25f, -0.25f) * invSize;
                // float2 uv1 = inUV + float2(0.25f, -0.25f) * invSize;
                // float2 uv2 = inUV + float2(-0.25f, 0.25f) * invSize;
                // float2 uv3 = inUV + float2(0.25f, 0.25f) * invSize;

                //需要采样上一级mipmap用于生成当前级的mipmap,由于长宽减半，像素量减少到原来的1/4,
                //对应的，当前mipmap一个像素值应该由之前的四个四个像素决定，
                //那么这样有如下关系，(x,y)点对应上一级(2x,2y)(2x,2y+1)(2x+1,2y)(2x+1,2y+1)四个点，
                //注意这里的点只是个点，实际上贴图是由纹素组成，纹素是有大小的，在这里，上一级纹素是当前纹素大小的
                //1/2
                float texelSize = _MainTex_TexelSize.x;
                
                float2 uv0 = inUV + texelSize;
                float2 uv1 = inUV + float2(    0, 0.5f) * texelSize;
                float2 uv2 = inUV + float2(-0.5f, 0.5f) * texelSize;
                float2 uv3 = inUV + float2( 0.5f, 0.5f) * texelSize;
				
                depth.x = tex2D(mainTex, uv0);
                depth.y = tex2D(mainTex, uv1);
                depth.z = tex2D(mainTex, uv2);
                depth.w = tex2D(mainTex, uv3);
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
                o.uv = TRANSFORM_TEX(i.texcoord, _MainTex);
                return o;
            }

            half4 frag (v2f i) : COLOR
            {
                // sample the texture
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                return col;
            }
            ENDHLSL
        }
    }
}
