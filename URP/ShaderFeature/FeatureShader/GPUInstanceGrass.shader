Shader "SEEDzy/URP/GPUInstance/Grass"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
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
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:setup

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            //CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4x4 _Obj2World;
            half4 _Color;
            //CBUFFER_END

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

            struct GrassInfo
            {
                //控制绘制的位置信息
                float4x4 transformMatrix;
                //控制纹理采样偏移信息
                float4   transformTex;
            };
            //computeBuffer
            StructuredBuffer<GrassInfo> _GrassInfos;
            
            struct a2v
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normalOS : NORMAL;
                uint instanceID : SV_InstanceID;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };
            
            v2f vert (a2v i)
            {
                v2f o;
                //根据ID获取对应实例化对象的GrassInfo
                GrassInfo grassInfo = _GrassInfos[i.instanceID];
                
                float3 positionOS = mul(grassInfo.transformMatrix, i.positionOS);
                //half3  normalOS   = mul(grassInfo.transform_Matrix, float4(i.normalOS, 0));
                float4 positionWS = mul(_Obj2World, float4(positionOS, 1));
                positionWS/= positionWS.w;
                o.positionCS = mul(GetWorldToHClipMatrix(), positionWS);
                
                o.uv = TRANSFORM_TEX(i.texcoord, _MainTex);
                return o;
            }

            half4 frag (v2f i) : COLOR
            {
                return _Color;
                // sample the texture
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                return col;
            }
            ENDHLSL
        }
    }
}

