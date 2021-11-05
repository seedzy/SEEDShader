#ifndef SEED_COMMON
#define SEED_COMMON

// Declares 3x3 matrix 'rotation', filled with tangent space basis
#define TANGENT_SPACE_ROTATION \
    float3 binormal = cross( normalize(i.normal), normalize(i.tangent.xyz) ) * i.tangent.w; \
    float3x3 rotation = float3x3( i.tangent.xyz, binormal, i.normal )
#endif