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
            Cull off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:setup

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include  "Assets/Shader/SEEDShader/URP/Lighting.hlsl"

            struct GrassInfo
            {
                //控制绘制的位置信息
                float4x4 transformMatrix;
                //控制纹理采样偏移信息
                float4   transformTex;
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4x4 _Obj2World;
            half4 _Color;
            //computeBuffer
            StructuredBuffer<GrassInfo> _GrassInfos;
            CBUFFER_END

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

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
                half3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                float4 positionCS : SV_POSITION;
            };
            
            v2f vert (a2v i)
            {
                v2f o;
                //根据ID获取对应实例化对象的GrassInfo
                GrassInfo grassInfo = _GrassInfos[i.instanceID];
                
                float3 positionOS = mul(grassInfo.transformMatrix, i.positionOS);
                half3  normalOS   = mul(grassInfo.transformMatrix, float4(i.normalOS, 0));
                float4 positionWS = mul(_Obj2World, float4(positionOS, 1));
                o.positionCS = mul(GetWorldToHClipMatrix(), positionWS);
                o.normalWS = TransformObjectToWorldNormal(normalOS);
                o.positionWS = positionWS.xyz;
                o.uv = TRANSFORM_TEX(i.texcoord, _MainTex);
                return o;
            }

            half4 frag (v2f i) : COLOR
            {
                // sample the texture
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                Light light = GetMainLight();
                
                SurfaceLightData surf;
                surf.albedo = col;
                surf.lightColor = light.color;
                surf.lightDirWS = normalize(light.direction);
                surf.normalWS = normalize(i.normalWS);
                surf.viewDirWS = GetWorldSpaceViewDir(i.positionWS);
                col.xyz = GetHLambertLight(surf, _Color);
                return col;
            }
            ENDHLSL
        }
        
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull off

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }
    
    
}

