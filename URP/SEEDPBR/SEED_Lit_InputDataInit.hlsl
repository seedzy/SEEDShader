#ifndef SEED_LIT_INPUTDATA_INIT_INCLUDED
#define SEED_LIT_INPUTDATA_INIT_INCLUDED

#include "Assets/Shader/SEEDShader/ShaderLibrary/BRDF.hlsl"

TEXTURE2D(_BaseMap);      SAMPLER(sampler_BaseMap); 
TEXTURE2D(_Smoe);         SAMPLER(sampler_Smoe); 



inline void InitLitSurfaceData(float2 uv, out SurfaceInput outSurfaceInput)
{
    half4 albedo  = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    half4 mixData = SAMPLE_TEXTURE2D(_Smoe, sampler_Smoe, uv);

    outSurfaceInput.albedo       = albedo;
    outSurfaceInput.smoothness   = mixData.r;
    outSurfaceInput.metallic     = mixData.g;
    outSurfaceInput.occlusion    = mixData.b;
    outSurfaceInput.emissionMask = mixData.a;
}



#endif