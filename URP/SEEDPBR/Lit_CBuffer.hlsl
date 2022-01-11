#ifndef LIT_CBUFFER
#define LIT_CBUFFER

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "LitUniversalCBuffer.hlsl"
    
CBUFFER_START(UnityPerMaterial)
LIT_UNIVERSAL_CBUFFER
CBUFFER_END

#endif