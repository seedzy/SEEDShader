Shader "SEEDzy/URP_Feature/PrePass"
{
	Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Pass {
			Tags{"LightMode"="UniversalForward"}
			ZWrite On
        	Cull Off
        	ColorMask 0
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			sampler2D _MainTex;
			
			struct a2v
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				
			};
			struct v2f 
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};
			v2f vert (a2v i)
			{
				v2f o;
				o.vertex = TransformObjectToHClip(i.vertex.xyz);
				o.uv = i.uv;
				return o;
			}
            float4 frag (v2f i) : SV_Target
			{
				//half a = tex2D(_MainTex, i.uv).a;
				//clip(a - 0.1);
                return 0;
			}
			ENDHLSL
		}
    }
}
