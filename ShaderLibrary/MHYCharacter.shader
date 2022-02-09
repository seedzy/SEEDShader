Shader "Unlit/MHYCharacter"
{
    Properties {
        _Scale ("Scale Compared to _MAYA", Float) = 0.01
        [Header(Utility Display)] [Enum(None, 0, vertex.r, 1, vertex.g, 2, vertex.b, 3, vertex.a, 4, diffuse, 5)] _UtilityDisplay1 ("Utility Display 1", Float) = 0
        [Enum(None, 0, shadow strength, 1, shadow ramp uv, 2, normal, 3, point light, 4)] _UtilityDisplay2 ("Utility Display 2", Float) = 0
        [Header(Color)] _Color ("Tint Color", Color) = (1,1,1,1)
        [Header(Element View)] _ElementViewEleID ("Element ID", Float) = 0
        [Header(Texture)] _MainTex ("Main Tex", 2D) = "white" { }
        [Enum(None, 0, AlphaTest, 1, Emission, 2, FaceBlush, 3)] _MainTexAlphaUse ("Main Tex Alpha Use", Float) = 0
        _MainTexAlphaCutoff ("Main Tex Alpha Cutoff", Range(0, 1)) = 0.5
        [Header(Coloring)] [Toggle(MAIN_TEX_COLORING_ON)] _MainTexColoring ("Use Main Tex Coloring", Float) = 0
        _MainTexTintColor ("Main Tex Tint Color", Color) = (1,1,1,1)
        [Header(Shadow)] [Toggle(TOON_LIGHTMAP_ON)] _UseToonLightMap ("Use Toon Light Map", Float) = 1
        [MHYToggle] _UseLightMapColorAO ("Use Light Map Color.g For AO", Float) = 1
        [MHYToggle] _UseVertexColorAO ("Use Vertex Color.r For AO", Float) = 1
        [MHYToggle] _UseCoolShadowColorOrTex ("Use Cool Shadow Color Or Tex", Float) = 0
        _LightMapTex ("Light Map Tex (RGB)", 2D) = "gray" { }
        _LightArea ("Light Area Threshold", Range(0, 1)) = 0.5
        _FirstShadowMultColor ("Warm Shadow Color", Color) = (0.9,0.7,0.75,1)
        _CoolShadowMultColor ("Cool Shadow Color", Color) = (0.9,0.7,0.75,1)
        [Header(Shadow Ramp)] [Toggle(SHADOW_RAMP_ON)] _UseShadowRamp ("Use Shadow Ramp", Float) = 0
        [MHYPackedGradient(_ShadowRampTex1 _ShadowRampTex2 _ShadowRampTex3 _ShadowRampTex4 _ShadowRampTex5 _CoolShadowRampTex1 _CoolShadowRampTex2 _CoolShadowRampTex3 _CoolShadowRampTex4 _CoolShadowRampTex5)] _PackedShadowRampTex ("Packed Shadow Ramp Tex", 2D) = "grey" { }
        _ShadowRampWidth ("Shadow Ramp Width", Range(0.01, 10)) = 1
        [MHYToggle] _UseVertexRampWidth ("Use Vertex Shadow Ramp Width", Float) = 0
        [Header(Shadow Transition)] [MHYToggle(SHADOW_TRANSITION_ON)] _UseShadowTransition ("Use Shadow Transition (only work when shadow ramp is off)", Float) = 0
        _ShadowTransitionRange ("Shadow Transition Range", Range(0.001, 0.2)) = 0.01
        _ShadowTransitionSoftness ("Shadow Transition Softness", Range(0, 2)) = 0.5
        [Header(Specular)] [Toggle(TOON_SPECULAR_ON)] _UseToonSpecular ("Use Toon Specular", Float) = 1
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _Shininess ("Specular Shininess", Range(0.1, 100)) = 10
        _SpecMulti ("Specular Multiply Factor", Range(0, 1)) = 0.1
        [Header(Face Blush)] _FaceBlushStrength ("Face Blush Strength", Range(0, 1)) = 0
        _FaceBlushColor ("Face Blush Color", Color) = (1,0.8,0.7,1)
        [Header(Face Map New)] [Toggle(FACE_MAP_NEW_ON)] _UseFaceMapNew ("Use Face Map", Float) = 0
        _FaceMapTex ("Face Map Tex (A Linear)", 2D) = "gray" { }
        _FaceMapRotateOffset ("Face Map Rotate Offset", Range(-1, 1)) = 0
        _FaceMapSoftness ("Face Map Softness", Range(0.01, 1)) = 0.01
        [Header(Emission(need use main tex alpha as mask))] _EmissionScaler ("Emission Scaler", Range(0, 100)) = 1
        _EmissionColor_MHY ("Emission Color", Color) = (1,1,1,1)
        [Header(Outline)] [Enum(None, 0, Normal, 1, Tangent, 2)] _OutlineType ("Outline Type", Float) = 2
        _OutlineWidth ("Outline Width", Range(0, 100)) = 0.04
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _MaxOutlineZOffset ("Max Outline Z Offset", Range(0, 100)) = 1
        _OutlineWidthAdjustZs ("Outline Width Adjust Dist Start (near, middle, far)", Vector) = (0.01,2,6,0)
        _OutlineWidthAdjustScales ("Outline Width Adjust Scale (near, middle, far)", Vector) = (0.105,0.245,0.6,0)
        [Header(Ambient Point Light)] [MHYToggle] _UseAmbientPoint ("Use Ambient Point light", Float) = 0
        [Enum(Result, 0, Strength, 1, Color, 2)] _AmbientPointUtility ("Ambient Point light Utility", Float) = 0
        _AmbientPointStrength ("Ambient Point light Strength", Range(0, 1)) = 0.1
        _AmbientPointRange ("Ambient Point light Range", Range(0, 2)) = 0.85
        _AmbientPointSoftness ("Ambient Point light Softness", Range(0, 1)) = 0.3
        _AmbientPointFlatness ("Ambient Point light Flatness", Range(1, 10)) = 1
        _AmbientPointYOffset ("Ambient Point light Y Offset", Range(0, 2)) = 0.37
        _AmbientPointColorDensity ("Ambient Point light Color Density", Range(0, 1)) = 0.5
        [Header(Material 2)] [MHYToggle] _UseMaterial2 ("Use Material 2", Float) = 0
        _Color2 ("Tint Color 2", Color) = (1,1,1,1)
        _FirstShadowMultColor2 ("Warm Shadow Color 2", Color) = (0.9,0.7,0.75,1)
        _CoolShadowMultColor2 ("Cool Shadow Color 2", Color) = (0.9,0.7,0.75,1)
        _Shininess2 ("Specular Shininess 2", Range(0.1, 100)) = 10
        _SpecMulti2 ("Specular Multiply Factor 2", Range(0, 1)) = 0.1
        _OutlineColor2 ("Outline Color 2", Color) = (0,0,0,1)
        [Header(Shadow Transition 2)] _ShadowTransitionRange2 ("Shadow Transition Range 2", Range(0.001, 0.2)) = 0.01
        _ShadowTransitionSoftness2 ("Shadow Transition Softness 2", Range(0, 2)) = 0.5
        [Header(Material 3)] [MHYToggle] _UseMaterial3 ("Use Material 3", Float) = 0
        _Color3 ("Tint Color 3", Color) = (1,1,1,1)
        _FirstShadowMultColor3 ("Warm Shadow Multiply Color 3", Color) = (0.9,0.7,0.75,1)
        _CoolShadowMultColor3 ("Cool Shadow Multiply Color 3", Color) = (0.9,0.7,0.75,1)
        _Shininess3 ("Specular Shininess 3", Range(0.1, 100)) = 10
        _SpecMulti3 ("Specular Multiply Factor 3", Range(0, 1)) = 0.1
        _OutlineColor3 ("Outline Color 3", Color) = (0,0,0,1)
        [Header(Shadow Transition 3)] _ShadowTransitionRange3 ("Shadow Transition Range 3", Range(0.001, 0.2)) = 0.01
        _ShadowTransitionSoftness3 ("Shadow Transition Softness 3", Range(0, 2)) = 0.5
        [Header(Material 4)] [MHYToggle] _UseMaterial4 ("Use Material 4", Float) = 0
        _Color4 ("Tint Color 4", Color) = (1,1,1,1)
        _FirstShadowMultColor4 ("Warm Shadow Multiply Color 4", Color) = (0.9,0.7,0.75,1)
        _CoolShadowMultColor4 ("Cool Shadow Multiply Color 4", Color) = (0.9,0.7,0.75,1)
        _Shininess4 ("Specular Shininess 4", Range(0.1, 100)) = 10
        _SpecMulti4 ("Specular Multiply Factor 4", Range(0, 1)) = 0.1
        _OutlineColor4 ("Outline Color 4", Color) = (0,0,0,1)
        [Header(Shadow Transition 4)] _ShadowTransitionRange4 ("Shadow Transition Range 4", Range(0.001, 0.2)) = 0.01
        _ShadowTransitionSoftness4 ("Shadow Transition Softness 4", Range(0, 2)) = 0.5
        [Header(Material 5)] [MHYToggle] _UseMaterial5 ("Use Material 5", Float) = 0
        _Color5 ("Tint Color 5", Color) = (1,1,1,1)
        _FirstShadowMultColor5 ("Warm Shadow Multiply Color 5", Color) = (0.9,0.7,0.75,1)
        _CoolShadowMultColor5 ("Cool Shadow Multiply Color 5", Color) = (0.9,0.7,0.75,1)
        _Shininess5 ("Specular Shininess 5", Range(0.1, 100)) = 10
        _SpecMulti5 ("Specular Multiply Factor 5", Range(0, 1)) = 0.1
        _OutlineColor5 ("Outline Color 5", Color) = (0,0,0,1)
        [Header(Shadow Transition 5)] _ShadowTransitionRange5 ("Shadow Transition Range 5", Range(0.001, 0.2)) = 0.01
        _ShadowTransitionSoftness5 ("Shadow Transition Softness 5", Range(0, 2)) = 0.5
        [Header(Back Face)] [Toggle(BACK_FACE_ON)] _DrawBackFace ("Draw Back Face", Float) = 0
        [MHYToggle] _UseBackFaceUV2 ("Use Back Face UV 2", Float) = 1
        [Header(Dithering)] [MHYToggle] _UsingDitherAlpha ("UsingDitherAlpha", Float) = 0
        _DitherAlpha ("Dither Alpha Value", Range(0, 1)) = 1
        _TextureBiasWhenDithering ("Texture Bias When Dithering", Float) = -1
        [Header(Plane Clipping)] [MHYToggle] _UseClipPlane ("Use Clip Plane", Float) = 0
        [MHYToggle] _ClipPlaneWorld ("Clip Plane In World Space", Float) = 1
        _ClipPlane ("Clip Plane", Vector) = (0,0,0,0)
        [Header(Metal)] [Toggle(METAL_MAT)] _MetalMaterial ("Metal Material", Float) = 0
        _MTMap ("Metal Map", 2D) = "white" { }
        _MTMapBrightness ("Metal Map Brightness", Float) = 1
        _MTMapTileScale ("Metal Map Tile Scale", Float) = 1
        _MTMapLightColor ("Metal Map Light Color", Color) = (1,1,1,1)
        _MTMapDarkColor ("Metal Map Dark Color", Color) = (0,0,0,0)
        _MTShadowMultiColor ("Metal Shadow Multiply Color", Color) = (0.8,0.8,0.8,0.8)
        _MTShininess ("Metal Shininess", Float) = 11
        _MTSpecularScale ("Metal Specular Scale", Float) = 60
        _MTSpecularAttenInShadow ("Metal Specular Attenuation in Shadow", Range(0, 1)) = 0.2
        _MTSpecularColor ("Metal Specular Color", Color) = (1,1,1,1)
        [Instanced GPU Skinning] _AnimTexture ("Animation Texture", 2D) = "white" { }
        _AnimBoneOffset ("Anim BoneOffset", Float) = 0
        _InstanceData ("", Float) = 0
        [Header(State)] [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2
        _PolygonOffsetFactor ("Polygon Offset Factor", Float) = 0
        _PolygonOffsetUnit ("Polygon Offset Unit", Float) = 0
        _OutlinePolygonOffsetFactor ("Outline Polygon Offset Factor", Float) = 0
        _OutlinePolygonOffsetUnit ("Outline Polygon Offset Unit", Float) = 0
        _CharacterAmbientSensorShadowOn ("", Float) = 0
        _CharacterAmbientSensorColorOn ("", Float) = 0
        [Header(ASE Properties)] _HitColor ("HitColor", Color) = (0,0,0,0)
        _ElementRimColor ("ElementRimColor", Color) = (0,0,0,0)
        _HitColorScaler ("HitColorScaler", Float) = 6
        _HitColorFresnelPower ("HitColorFresnelPower", Float) = 1.5
        _EmissionStrengthLerp ("EmissionStrengthLerp", Range(0, 1)) = 0
        _ASEHeader ("", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
