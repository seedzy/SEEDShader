Shader "SEEDzy/SEEDPBR/Stylized_Lit"
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
        [Toggle(_MIXMAP_ON)]_MixMapOn("MixMapOn", float) = 1
        [Toggle(_NORMALMAP)]_NormalMapOn("NormalMapOn", float) = 1
        
        [Header(Stylized)]
        _DarkAreasColor("DarkAreasColor", Color) = (0,0,0,0)
        _DarkAreasSmooth("DarkAreasSmooth", Range(0,0.5)) = 0.01
        _DarkAreasThreshold("DarkAreasThreshold", Range(0,1)) = 0.4
        [Space]
        _SpecularThreshold("SpecularThreshold", Range(0,0.5)) = 0.07
        _SpecularSmooth("SpecularSmooth", Range(0,0.5)) = 0.01
        _SpecularStrength("SpecularStrength", float) = 1.5
        _SpecularMask("SpecularMask", 2D) = "White"{}
        [Space]
        [Toggle(_GRADIENTMAP_ON)]_GradientMapOn("GradientMapOn", float) = 0
        _GradientMap("GradientMap", 2D) = "white" {}
        
        _BrushWork("BrushWork", 2D) = "white" {}
        _BrushStrength("BrushStrength", range(0,1)) = 0
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
            #pragma shader_feature_local_fragment _GRADIENTMAP_ON
            #pragma shader_feature_local _NORMALMAP
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Stylized_Lit_Input.hlsl"
            #include "Stylized_Lit_Pass.hlsl"

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
