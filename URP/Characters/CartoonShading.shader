Shader "SEEDzy/URP/Character/CartoonPreview"
{
    Properties
    {
        [Header(High Level Setting)]
        [Toggle(_IS_FACE)]_IsFace("Is Face? (please turn on if this is a face material)", Float) = 0
        [Enum (UnityEngine.Rendering.CullMode)]_Culling("Culling", float) = 0

        // all properties will try to follow URP Lit shader's naming convention
        // so switching your URP lit material's shader to this toon lit shader will preserve most of the original properties if defined in this shader

        // for URP Lit shader's naming convention, see URP's Lit.shader
        [Header(Base Color)]
        [MainTexture]_BaseMap("_BaseMap (Albedo)", 2D) = "white" {}
        [HDR][MainColor]_BaseColor("_BaseColor", Color) = (1,1,1,1)

        [Header(Alpha)]
        [Toggle(_UseAlphaClipping)]_UseAlphaClipping("_UseAlphaClipping", Float) = 0
        _Cutoff("_Cutoff (Alpha Cutoff)", Range(0.0, 1.0)) = 0.5

//        [Header(Emission)]
//        [Toggle]_UseEmission("_UseEmission (on/off Emission completely)", Float) = 0
//        [HDR] _EmissionColor("_EmissionColor", Color) = (0,0,0)
//        _EmissionMulByBaseColor("_EmissionMulByBaseColor", Range(0,1)) = 0
//        [NoScaleOffset]_EmissionMap("_EmissionMap", 2D) = "white" {}
//        _EmissionMapChannelMask("_EmissionMapChannelMask", Vector) = (1,1,1,0)

//        [Header(Occlusion)]
//        [Toggle]_UseOcclusion("_UseOcclusion (on/off Occlusion completely)", Float) = 0
//        _OcclusionStrength("_OcclusionStrength", Range(0.0, 1.0)) = 1.0
//        [NoScaleOffset]_OcclusionMap("_OcclusionMap", 2D) = "white" {}
//        _OcclusionMapChannelMask("_OcclusionMapChannelMask", Vector) = (1,0,0,0)
//        _OcclusionRemapStart("_OcclusionRemapStart", Range(0,1)) = 0
//        _OcclusionRemapEnd("_OcclusionRemapEnd", Range(0,1)) = 1

        [Header(Lighting)]
        _LightMap("CharacterLightMap", 2D) = "White" {}
        _IndirectLightMinColor("_IndirectLightMinColor", Color) = (0.1,0.1,0.1,1) // can prevent completely black if lightprobe not baked
        _IndirectLightMultiplier("_IndirectLightMultiplier没用", Range(0,1)) = 1
        _DirectLightMultiplier("_DirectLightMultiplier没用", Range(0,1)) = 1
        _CelShadeMidPoint("明暗分界", Range(-1,1)) = -0.5
        _CelShadeSoftness("明暗柔和度", Range(0,1)) = 0.05
        _LightRatio("LightRatio", range(0,1)) = 0.3
        [HDR]_EmissionPower("EmissionPower", Range(0, 10)) = 1
        [Space]
        [Header(ShadowRamp)]
        [Toggle(_USE_RAMPMAP)]_UseRampMap("Use Ramp Map", float) = 1
        [Toggle]_UseVertexRampWidth("UseVertexRampWidth", float) = 1
        _RampMap("ShadowRampMap", 2D) =  "white" {}
        _FaceShadowMultiCol("FaceShadowMultiColor", Color) = (0.95, 0.74, 0.74, 1)
        _LightArea("LightArea", range(0,1)) = 0.5
        _RampMapLayerSwitch("RampMapLayerSwitch", vector) = (0.00,0.00,0.00,0.00)
        _ColorTone("ColorTone", Range(0,1)) = 1
        [Space]
        _MainLightIgnoreCelShade("_MainLightIgnoreCelShade没用", Range(0,1)) = 0
        _AdditionalLightIgnoreCelShade("_AdditionalLightIgnoreCelShade没用", Range(0,1)) = 0.9
        
        [Header(MetaLight)]
        _MT("MetalTexture", 2D) =  "White" {}
        _Metal_Brightness("MetalBrightness", range(0, 5)) = 3
        _Metal_SpecPower("MetalSpecularPower", range(0.01, 100)) = 90
        _Metal_SpecAttenInShadow("MetalSpecularAttenuationInShadow", range(0, 1)) = 0.2
        _Metal_LightColor("MetalLightColor", Color) = (1,1,1,1)
        _Metal_DarkColor("MetalDarkColor", Color) = (0.58, 0.3, 0.46, 1)
        _Metal_ShadowMultiColor("MetalShadowMultiColor", Color) = (0.77, 0.67, 0.76, 1)
        _Metal_SpecColor("MetalSpecluarColor", Color) = (1, 1, 1, 1)

        [Header(Shadow mapping)]
        _ReceiveShadowMappingAmount("_ReceiveShadowMappingAmount", Range(0,1)) = 0.65
        _ReceiveShadowMappingPosOffset("_ReceiveShadowMappingPosOffset", Float) = 0
        _ShadowMapColor("_ShadowMapColor", Color) = (1,0.825,0.78)

        [Header(Outline)]
        _OutlineWidth("_OutlineWidth (World Space)", Range(0,10)) = 1
        _OutlineColor("_OutlineColor", Color) = (0.5,0.5,0.5,1)
        _OutlineZOffset("_OutlineZOffset (View Space)", Range(0,1)) = 0.0001
        [NoScaleOffset]_OutlineZOffsetMaskTex("_OutlineZOffsetMask (black is apply ZOffset)", 2D) = "black" {}
        _OutlineZOffsetMaskRemapStart("_OutlineZOffsetMaskRemapStart", Range(0,1)) = 0
        _OutlineZOffsetMaskRemapEnd("_OutlineZOffsetMaskRemapEnd", Range(0,1)) = 1
        
        [Header(Specular)]
        [Toggle]_UseSpecularMask("_SpecularMask (on/off Specular completely)", Float) = 0
        _SpecPower ("Power",  Range(0.01,15)) = 15
        _SpecPower2("Power2", Range(0.01,15)) = 10
        _SpecPower3("Power3", Range(0.01,15)) = 14.6
        _SpecPower4("Power4", Range(0.01,15)) = 10
        _SpecPower5("Power5", Range(0.01,15)) = 10

        [HDR]_SpecColor("SpecularColor", Color) = (1,1,1,1)
        _SpecColorMulti ("ColorMulti ", Range(0, 1)) = 0.8
        _SpecColorMulti2("ColorMulti2", Range(0, 1)) = 0.1
        _SpecColorMulti3("ColorMulti3", Range(0, 1)) = 0.8
        _SpecColorMulti4("ColorMulti4", Range(0, 1)) = 0.1
        _SpecColorMulti5("ColorMulti5", Range(0, 1)) = 0.1

        [Header(Test)]
        [Toggle(_USE_NORMALSH)]_TestSHLight("Flattening IndirectLight Off", float) = 0
    }
    SubShader
    {       
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue"="Geometry"
        }
        Cull [_Culling]
        // We can extract duplicated hlsl code from all passes into this HLSLINCLUDE section. Less duplicated code = Less error
        //你是对的
        HLSLINCLUDE

        // all Passes will need this keyword
        #pragma shader_feature_local_fragment _UseAlphaClipping

        ENDHLSL

        // [#0 Pass - ForwardLit]
        // Shades GI, all lights, emission and fog in a single pass.
        // Compared to Builtin pipeline forward renderer, URP forward renderer will
        // render a scene with multiple lights with less drawcalls and less overdraw.
        Pass
        {               
            Name "ForwardLit"
            Tags
            {
                // "Lightmode" matches the "ShaderPassName" set in UniversalRenderPipeline.cs. 
                // SRPDefaultUnlit and passes with no LightMode tag are also rendered by Universal Render Pipeline

                // "Lightmode" tag must be "UniversalForward" in order to render lit objects in URP.
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM

            #pragma shader_feature_local_fragment _USE_NORMALSH
            #pragma shader_feature_local_fragment _USE_RAMPMAP 
            #pragma shader_feature_local _IS_FACE 
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            // ---------------------------------------------------------------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            // ---------------------------------------------------------------------------------------------

            #pragma vertex VertexShaderWork
            #pragma fragment ShadeFinalColor

            // because this pass is just a ForwardLit pass, no need any special #define
            // (no special #define)

            // all shader logic written inside this .hlsl, remember to write all #define BEFORE writing #include
            #include "ToonSurfaceLitPass.hlsl"

            ENDHLSL
        }
        
        // [#1 Pass - Outline]
        // Same as the above "ForwardLit" pass, but 
        // -vertex position are pushed out a bit base on normal direction
        // -also color is tinted
        // -Cull Front instead of Cull Back because Cull Front is a must for all extra pass outline method
        Pass 
        {
            Name "Outline"
            Tags 
            {
                // IMPORTANT: don't write this line for any custom pass! else this outline pass will not be rendered by URP!
                //"LightMode" = "UniversalForward" 

                // [Important CPU performance note]
                // If you need to add a custom pass to your shader (outline pass, planar shadow pass, XRay pass when blocked....),
                // (0) Add a new Pass{} to your shader
                // (1) Write "LightMode" = "YourCustomPassTag" inside new Pass's Tags{}
                // (2) Add a new custom RendererFeature(C#) to your renderer,
                // (3) write cmd.DrawRenderers() with ShaderPassName = "YourCustomPassTag"
                // (4) if done correctly, URP will render your new Pass{} for your shader, in a SRP-batcher friendly way (usually in 1 big SRP batch)

                // For tutorial purpose, current everything is just shader files without any C#, so this Outline pass is actually NOT SRP-batcher friendly.
                // If you are working on a project with lots of characters, make sure you use the above method to make Outline pass SRP-batcher friendly!
            }

            Cull Front // Cull Front is a must for extra pass outline method

            HLSLPROGRAM

            // Direct copy all keywords from "ForwardLit" pass
            // ---------------------------------------------------------------------------------------------
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            // ---------------------------------------------------------------------------------------------
            #pragma multi_compile_fog
            // ---------------------------------------------------------------------------------------------

            #pragma vertex VertexShaderWork
            #pragma fragment ShadeFinalColor

            // because this is an Outline pass, define "ToonShaderIsOutline" to inject outline related code into both VertexShaderWork() and ShadeFinalColor()
            #define ToonShaderIsOutline

            // all shader logic written inside this .hlsl, remember to write all #define BEFORE writing #include
            #include "ToonSurfaceLitPass.hlsl"

            ENDHLSL
        }
 
        // ShadowCaster pass. Used for rendering URP's shadowmaps
//        Pass
//        {
//            Name "ShadowCaster"
//            Tags{"LightMode" = "ShadowCaster"}
//
//            // more explict render state to avoid confusion
//            ZWrite On // the only goal of this pass is to write depth!
//            ZTest LEqual // early exit at Early-Z stage if possible            
//            ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
//            Cull Back // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader
//
//            HLSLPROGRAM
//
//            // the only keywords we need in this pass = _UseAlphaClipping, which is already defined inside the HLSLINCLUDE block
//            // (so no need to write any multi_compile or shader_feature in this pass)
//
//            #pragma vertex VertexShaderWork
//            #pragma fragment BaseColorAlphaClipTest // we only need to do Clip(), no need shading
//
//            // because it is a ShadowCaster pass, define "ToonShaderApplyShadowBiasFix" to inject "remove shadow mapping artifact" code into VertexShaderWork()
//            #define ToonShaderApplyShadowBiasFix
//
//            // all shader logic written inside this .hlsl, remember to write all #define BEFORE writing #include
//            #include "SimpleURPToonLitOutlineExample_Shared.hlsl"
//
//            ENDHLSL
//        }
//
//        // DepthOnly pass. Used for rendering URP's offscreen depth prepass (you can search DepthOnlyPass.cs in URP package)
//        // For example, when depth texture is on, we need to perform this offscreen depth prepass for this toon shader. 
//        Pass
//        {
//            Name "DepthOnly"
//            Tags{"LightMode" = "DepthOnly"}
//
//            // more explict render state to avoid confusion
//            ZWrite On // the only goal of this pass is to write depth!
//            ZTest LEqual // early exit at Early-Z stage if possible            
//            ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
//            Cull Back // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader
//
//            HLSLPROGRAM
//
//            // the only keywords we need in this pass = _UseAlphaClipping, which is already defined inside the HLSLINCLUDE block
//            // (so no need to write any multi_compile or shader_feature in this pass)
//
//            #pragma vertex VertexShaderWork
//            #pragma fragment BaseColorAlphaClipTest // we only need to do Clip(), no need color shading
//
//            // because Outline area should write to depth also, define "ToonShaderIsOutline" to inject outline related code into VertexShaderWork()
//            #define ToonShaderIsOutline
//
//            // all shader logic written inside this .hlsl, remember to write all #define BEFORE writing #include
//            #include "SimpleURPToonLitOutlineExample_Shared.hlsl"
//
//            ENDHLSL
//        }
        

        // Starting from version 10.0.x, URP can generate a normal texture called _CameraNormalsTexture. 
        // To render to this texture in your custom shader, add a Pass with the name DepthNormals. 
        // For example, see the implementation in Lit.shader.
        // TODO: DepthNormals pass (see URP's Lit.shader)
        /*
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            //...
        }
        */
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}