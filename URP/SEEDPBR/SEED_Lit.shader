Shader "SEEDzy/URP/SEEDPBR/SEED_Lit"
{
    Properties
    {
        _BaseMap ("BaseMap", 2D) = "white" {}
        _Smoe    ("SMOE", 2D) = "Black"{}
        _BRDF    ("BRDF", 2D) = "Black"{}
        
        
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
            
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lit_CBuffer.hlsl"
            #include "SEED_Lit_InputDataInit.hlsl"
            #include "SEED_Lit_Forward.hlsl"

            ENDHLSL
        }
        
        Pass
        {
            
        }
            
    }
}
