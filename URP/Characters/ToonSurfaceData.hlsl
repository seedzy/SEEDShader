#ifndef TOON_SURFACE_DATA
#define TOON_SURFACE_DATA


struct  ToonSurfaceData
{
    half3   albedo;
    half    alpha;
    half3   emission;
    half    occlusion;
    half4   vertexColor;
    //specularMask, shadowWeight, specular?, rampMask
    half4   lightMap;
};

#endif