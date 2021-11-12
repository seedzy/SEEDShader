Shader "SEEDzy/URP/PostProcess/DOF"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FocalDistance("FocalDistance", float) = 50
        _DepthOfField("DepthOfField", float) = 10
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _FocalDistance;
            float _DepthOfField;
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
                float depth = Linear01Depth(SampleSceneDepth(i.uv), _ZBufferParams) * _ProjectionParams.z;
                float focalNear = _FocalDistance - _DepthOfField;
                float focalFar = _FocalDistance + _DepthOfField;
                if(depth >= focalNear && depth <= focalFar)
                {
                    
                }
                
                return half4(depth.rrr, 1);
            }
            ENDHLSL
        }
    }
}
