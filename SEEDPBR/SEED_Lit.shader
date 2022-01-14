Shader "SEEDzy/SEEDPBR/SEED_Lit"
{
    Properties
    {
        _BaseMap  ("BaseMap", 2D) = "white" {}
        _Albedo   ("BaseColor", COlor) = (1,1,1,1)
        _BumpMap  ("Normal", 2D) = "Black"{}
        _BumpScale("BumpScale", range(-1, 1)) = 1
        _Smoe     ("SMOE", 2D) = "Black"{}
        _SpecularBRDFTex    ("BRDF", 2D) = "Black"{}
        _Smoothness  ("s", range(0,1)) = 1
        _Metallic    ("M", range(0,1)) = 1
        _Occlusion   ("O", range(0,1)) = 1
        _Emission    ("E", range(0,1)) = 0
        [HDR]_EmissionColor("EmissionPower", Color) = (1,1,1,1)
        
        
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

            #pragma shader_feature_local_fragment _MIXMAP_OFF
            
            #pragma vertex vert
            #pragma fragment frag

            #define _NORMALMAP

            #include "Lit_CBuffer.hlsl"
            #include "SEED_Lit_Input.hlsl"
            #include "SEED_Lit_Forward.hlsl"

            ENDHLSL
        }
        
        Pass
        {
            
        }
            
    }
}
