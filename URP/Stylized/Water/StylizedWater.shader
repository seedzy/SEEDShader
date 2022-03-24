Shader "SEEDzy/URP/Stylized/Water"
{
    Properties
    {
        _BaseMap  ("BaseMap", 2D) = "white" {}
        _Albedo   ("BaseColor", COlor) = (1,1,1,1)
        _BumpMap  ("Normal", 2D) = "Black"{}
        _BumpScale("BumpScale", range(-1, 1)) = 1
        _Smoe     ("SMOE", 2D) = "White"{}
        _SpecularBRDFTex    ("BRDF", 2D) = "Black"{}
        _Smoothness  ("s", range(0,1)) = 0.5
        _Metallic    ("M", range(0,1)) = 0
        _Occlusion   ("O", range(0,1)) = 1
        _Emission    ("E", range(0,1)) = 0
        [HDR]_EmissionColor("EmissionPower", Color) = (1,1,1,1)
        [Toggle(_MIXMAP_ON)]_MixMapOn("MixMapOn", float) = 0
        [Toggle(_NORMALMAP)]_NormalMapOn("NormalMapOn", float) = 0
        
        _IOR("折射率(Index Of Refraction)", Range(1, 3)) = 1
        
        // Blending state
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 300

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            
//            Blend[_SrcBlend][_DstBlend]
//            ZWrite[_ZWrite]
//            Cull[_Cull]
            //Cull off
            
            
            HLSLPROGRAM

            #pragma shader_feature_local_fragment _MIXMAP_ON
            #pragma shader_feature_local _NORMALMAP
            
            #pragma vertex vert
            #pragma fragment frag

            #include "SEED_StylizedWater_Input.hlsl"
            #include "SEED_StylizedWater_Forward.hlsl"

            ENDHLSL
        }
        
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
            
    }
}
