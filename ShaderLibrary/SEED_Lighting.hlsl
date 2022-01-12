#ifndef SEED_LIGHTING_INCLUDED
#define SEED_LIGHTING_INCLUDED

///////////////////////////include
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
#include "Assets/Shader/SEEDShader/ShaderLibrary/BRDF.hlsl"
////////////////////////////////////////////////////

inline void InitBRDFInputData(InputData inputData, SurfaceInput surfaceInput, half3 lightDirectionWS, out BRDFInput brdfInput)
{
    half3 H    = saturate(lightDirectionWS + inputData.viewDirectionWS);
    half HdotV = saturate(dot(H, inputData.viewDirectionWS));
    half3 f0   = GetF0(surfaceInput.albedo, surfaceInput.metallic);
    half3 ks   = FresnelTerm_UE(HdotV, f0);
    
    brdfInput.ks    = ks;
    brdfInput.kd    = (1 - ks)(1 - surfaceInput.metallic);
    brdfInput.NdotH = saturate(dot(inputData.normalWS, H));                         //共使用：1 次
    brdfInput.NdotL = saturate(dot(inputData.normalWS, lightDirectionWS));          //共使用：2 次
    brdfInput.NdotV = saturate(dot(inputData.normalWS, inputData.viewDirectionWS)); //共使用：2 次
    brdfInput.LdotV = saturate(dot(lightDirectionWS, inputData.viewDirectionWS));   //共使用：1 次
}

void IndirectLight()
{
    
}

half3 DirectLight(InputData inputData, SurfaceInput surfaceInput, BRDFInput brdfInput)
{
    half perceptualRoughness = 1 - surfaceInput.smoothness;
    //没记错的话是epic说的平方更好
    half roughness = perceptualRoughness * perceptualRoughness;
    
    half3 diffuseTerm  = brdfInput.kd * DisneyDiffuse(brdfInput.NdotV, brdfInput.NdotL, brdfInput.LdotV, perceptualRoughness) * surfaceInput.albedo;
    half3 spevularTerm = brdfInput.ks * DV_SmithJointGGX_HDRP(brdfInput.NdotH, brdfInput.NdotL, brdfInput.NdotV, roughness);
    return diffuseTerm + spevularTerm;
}


half4 DisneyDiffuseSpecularLutPBR(InputData inputData, SurfaceInput surfaceInput )
{
//     #ifdef _SPECULARHIGHLIGHTS_OFF
//     bool specularHighlightsOff = true;
// #else
//     bool specularHighlightsOff = false;
// #endif
    BRDFInput brdfInput = BRDFInput(0);
    InitBRDFInputData(inputData, surfaceInput, brdfInput);
    

//     BRDFData brdfDataClearCoat = (BRDFData)0;
// #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
//     // base brdfData is modified here, rely on the compiler to eliminate dead computation by InitializeBRDFData()
//     InitializeBRDFDataClearCoat(surfaceData.clearCoatMask, surfaceData.clearCoatSmoothness, brdfData, brdfDataClearCoat);
// #endif
//
//     // To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
// #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
//     half4 shadowMask = inputData.shadowMask;
// #elif !defined (LIGHTMAP_ON)
//     half4 shadowMask = unity_ProbesOcclusion;
// #else
//     half4 shadowMask = half4(1, 1, 1, 1);
// #endif
//
//     Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);
//
//     #if defined(_SCREEN_SPACE_OCCLUSION)
//         AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
//         mainLight.color *= aoFactor.directAmbientOcclusion;
//         surfaceData.occlusion = min(surfaceData.occlusion, aoFactor.indirectAmbientOcclusion);
//     #endif
//
//     MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);
//     half3 color = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
//                                      inputData.bakedGI, surfaceData.occlusion,
//                                      inputData.normalWS, inputData.viewDirectionWS);
//     color += LightingPhysicallyBased(brdfData, brdfDataClearCoat,
//                                      mainLight,
//                                      inputData.normalWS, inputData.viewDirectionWS,
//                                      surfaceData.clearCoatMask, specularHighlightsOff);
//
// #ifdef _ADDITIONAL_LIGHTS
//     uint pixelLightCount = GetAdditionalLightsCount();
//     for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
//     {
//         Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
//         #if defined(_SCREEN_SPACE_OCCLUSION)
//             light.color *= aoFactor.directAmbientOcclusion;
//         #endif
//         color += LightingPhysicallyBased(brdfData, brdfDataClearCoat,
//                                          light,
//                                          inputData.normalWS, inputData.viewDirectionWS,
//                                          surfaceData.clearCoatMask, specularHighlightsOff);
//     }
// #endif
//
// #ifdef _ADDITIONAL_LIGHTS_VERTEX
//     color += inputData.vertexLighting * brdfData.diffuse;
// #endif
//
//     color += surfaceData.emission;
//     
//     return half4(color, surfaceData.alpha);
}




#endif