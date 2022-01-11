// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "SEEDzy/URP/RenderFeature/Bloom" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Bloom ("Bloom (RGB)", 2D) = "black" {}
		_LuminanceThreshold ("Luminance Threshold", Float) = 0.5
		_BlurSize ("Blur Size", Float) = 10
	}
	SubShader {
		HLSLINCLUDE
		
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		CBUFFER_START(UntiyPerMaterial)
		half4 _MainTex_TexelSize;
		float _LuminanceThreshold;
		float _BlurSize;
		CBUFFER_END
		
		TEXTURE2D(_BloomMaskRT);
        SAMPLER(sampler_BloomMaskRT);
		
		sampler2D _MainTex;
		sampler2D _BloomS;
		sampler2D _CameraOpaqueTexture;
		struct a2v
		{
		    float4 vertex : POSITION;
		    half2 texcoord : TEXCOORD0;
		};
		
		struct v2f {
			float4 pos : SV_POSITION; 
			half2 uv : TEXCOORD0;
		};

		v2f vertBloomMask(a2v v)
		{
			v2f o;
			o.pos = TransformObjectToHClip(v.vertex.xyz);
			o.uv = v.texcoord;		 
			return o;
		}
		
		half4 fragBloomMask(v2f i) : COLOR
		{
			return half4(1,1,1,1);
		}

		half4 fragNoBloomMask(v2f i) : COLOR
		{
			return half4(0,0,0,1);
		}
		
		////////////////////////////////////////////////
		v2f vertExtractBright(a2v v) {
			v2f o;
			
			o.pos = TransformObjectToHClip(v.vertex.xyz);
			
			o.uv = v.texcoord;
					 
			return o;
		}
		
		half luminance(half4 color) {
			return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
		}
		
		half4 fragExtractBright(v2f i) : SV_Target {
			half4 c = tex2D(_MainTex, i.uv);
			half mask = SAMPLE_TEXTURE2D(_BloomMaskRT, sampler_BloomMaskRT, i.uv).r;
			//half val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);
			
			return c * mask;
		}
		//////////////////////////////////////////////////
		
		struct v2fBloom {
			float4 pos : SV_POSITION; 
			half4 uv : TEXCOORD0;
		};
		
		v2fBloom vertBloom(a2v v) {
			v2fBloom o;
			
			o.pos = TransformObjectToHClip (v.vertex.xyz);
			o.uv.xy = v.texcoord;		
			o.uv.zw = v.texcoord;
			
			// #if UNITY_UV_STARTS_AT_TOP			
			// if (_MainTex_TexelSize.y < 0.0)
			// 	o.uv.w = 1.0 - o.uv.w;
			// #endif
				        	
			return o; 
		}
		
		half4 fragBloom(v2fBloom i) : SV_Target {
			return tex2D(_MainTex, i.uv.xy) + tex2D(_CameraOpaqueTexture, i.uv.zw);
		} 
		
		ENDHLSL
		
		ZTest Always Cull Off ZWrite Off
		
		Pass
		{
			Tags { "LightMode" = "UniversalForward" }
			Name "WriteBloomMask"
			HLSLPROGRAM  
			#pragma vertex vertBloomMask  
			#pragma fragment fragBloomMask 
			ENDHLSL
		}
		Pass
		{
			Tags { "LightMode" = "UniversalForward" }
			Name "WriteNoBloomMask"
			HLSLPROGRAM  
			#pragma vertex vertBloomMask  
			#pragma fragment fragNoBloomMask 
			ENDHLSL
		}
		
		Pass {  
			HLSLPROGRAM  
			#pragma vertex vertExtractBright  
			#pragma fragment fragExtractBright  
			
			ENDHLSL  
		}
		
		UsePass "SEEDzy/URP/RenderFeature/Gaussian Blur/GAUSSIAN_BLUR_VERTICAL"
		
		UsePass "SEEDzy/URP/RenderFeature/Gaussian Blur/GAUSSIAN_BLUR_HORIZONTAL"
		
		Pass {  
			HLSLPROGRAM  
			#pragma vertex vertBloom  
			#pragma fragment fragBloom  
			
			ENDHLSL  
		}
	}
	FallBack Off
}
