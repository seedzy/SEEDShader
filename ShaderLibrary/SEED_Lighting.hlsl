#ifndef SEED_LIGHTING_INCLUDED
#define SEED_LIGHTING_INCLUDED

///////////////////////////include
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
#include "Assets/Shader/SEEDShader/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
////////////////////////////////////////////////////


inline void InitBRDFInput(InputData inputData, SurfaceInput surfaceInput, half3 lightDirectionWS, out BRDFInput brdfInput)
{
    half3 H    = normalize(lightDirectionWS + inputData.viewDirectionWS);
    half perceptualRoughness = 1 - surfaceInput.smoothness;
    
    brdfInput.f0        = GetF0(surfaceInput.albedo.rgb, surfaceInput.metallic);        //共使用：2 次
    
    brdfInput.perceptualRoughness = perceptualRoughness;                                //共使用：2 次
    //没记错的话是epic说的平方更好
    brdfInput.roughness = max(perceptualRoughness * perceptualRoughness, HALF_MIN_SQRT);//共使用：3 次
    brdfInput.NdotH     = saturate(dot(inputData.normalWS, H));                         //共使用：1 次
    brdfInput.NdotL     = saturate(dot(inputData.normalWS, lightDirectionWS));          //共使用：2 次
    brdfInput.NdotV     = saturate(dot(inputData.normalWS, inputData.viewDirectionWS)); //共使用：3 次
    brdfInput.LdotV     = saturate(dot(lightDirectionWS, inputData.viewDirectionWS));   //共使用：1 次
    brdfInput.HdotV     = saturate(dot(H, inputData.viewDirectionWS));                  //共使用：2 次
}

half3 IndirectLight(InputData inputData, SurfaceInput surfaceInput, BRDFInput brdfInput)
{
    half3 ks = FresnelSchlickRoughness(brdfInput.HdotV, brdfInput.f0, brdfInput.roughness);
    half3 kd = (1 - ks) * (1 - surfaceInput.metallic);;
    
    half3 reflectVector = reflect(-inputData.viewDirectionWS, inputData.normalWS);
    half2 envBRDF = BRDF_Specular_Lut(brdfInput.NdotV, brdfInput.roughness);
    
    half3 iblDiffuse  = inputData.bakedGI;
    half3 iblSpecular = GlossyEnvironmentReflection(reflectVector, brdfInput.perceptualRoughness, surfaceInput.occlusion);

    half3 diffuseTerm  = kd * iblDiffuse * surfaceInput.albedo.rgb * surfaceInput.occlusion;
    half3 specularTerm = iblSpecular * (ks * envBRDF.r + envBRDF.g);
    return diffuseTerm + specularTerm;
}

half3 DirectLight(InputData inputData, SurfaceInput surfaceInput, BRDFInput brdfInput)
{
    half3 ks = FresnelTerm_UE(brdfInput.HdotV, brdfInput.f0);
    half3 kd = (1 - ks) * (1 - surfaceInput.metallic);
    
    half3 diffuseTerm  = kd * DisneyDiffuse(brdfInput.NdotV, brdfInput.NdotL, brdfInput.LdotV, brdfInput.perceptualRoughness) * surfaceInput.albedo.rgb;
    half3 spevularTerm = ks * DV_SmithJointGGX_HDRP(brdfInput.NdotH, brdfInput.NdotL, brdfInput.NdotV, brdfInput.roughness);
    
    return diffuseTerm + spevularTerm;
}


half4 DisneyDiffuseSpecularLutPBR(InputData inputData, SurfaceInput surfaceInput )
{
    Light light = GetMainLight();

    half3 lightDirectionWS = normalize(light.direction);
    BRDFInput brdfInput;
    InitBRDFInput(inputData, surfaceInput, lightDirectionWS, brdfInput);

    half3 color = DirectLight(inputData, surfaceInput, brdfInput);
    color *= light.color * saturate(dot(inputData.normalWS, lightDirectionWS));
    //URP包括Builtin都没除pi，为了保持亮度，这里先加回去
    color *= PI;
    
    color += IndirectLight(inputData, surfaceInput, brdfInput);

    color += surfaceInput.emissionMask * surfaceInput.albedo.rgb;

    
    //return surfaceInput.albedo;
    return half4(color, surfaceInput.albedo.a);

}



//-----------------------------------------------------Stylized
half3 DirectLight_Stylized(InputData inputData, SurfaceInput surfaceInput, BRDFInput brdfInput)
{
    half3 ks = FresnelTerm_UE(brdfInput.HdotV, brdfInput.f0);
    half3 kd = (1 - ks) * (1 - surfaceInput.metallic);
    
    half3 diffuseTerm  = kd * surfaceInput.albedo.rgb;
    half3 spevularTerm = ks * DV_SmithJointGGX_HDRP(brdfInput.NdotH, brdfInput.NdotL, brdfInput.NdotV, brdfInput.roughness);
    
    return diffuseTerm + spevularTerm;
}

half4 StylizedWaterShading(InputData inputData, SurfaceInput surfaceInput)
{
    Light light = GetMainLight();

    half3 lightDirectionWS = normalize(light.direction);

    half3 refractRay = refract(-inputData.viewDirectionWS, inputData.normalWS, 1 / surfaceInput.IOR);

    //inputData.viewDirectionWS = refractRay;
    
    BRDFInput brdfInput;
    InitBRDFInput(inputData, surfaceInput, lightDirectionWS, brdfInput);

    half3 color = DirectLight(inputData, surfaceInput, brdfInput);
    color *= light.color * saturate(dot(inputData.normalWS, lightDirectionWS));
    //URP包括Builtin都没除pi，为了保持亮度，这里先加回去
    color *= PI;
    
    color += IndirectLight(inputData, surfaceInput, brdfInput);
    
    color += surfaceInput.emissionMask * surfaceInput.albedo.rgb;

    
    //return surfaceInput.albedo;
    return half4(color, surfaceInput.albedo.a);
}
// half4 DisneyDiffuseSpecularLutPBR_Stylized(InputData inputData, SurfaceInput surfaceInput)
// {
//     Light light = GetMainLight();
//
//     half3 lightDirectionWS = normalize(light.direction);
//     BRDFInput brdfInput;
//     InitBRDFInput(inputData, surfaceInput, lightDirectionWS, brdfInput);
//
//     half3 color = DirectLight(inputData, surfaceInput, brdfInput);
//     color *= light.color * saturate(dot(inputData.normalWS, lightDirectionWS));
//     //URP包括Builtin都没除pi，为了保持亮度，这里先加回去
//     color *= PI;
//     
//     color += IndirectLight(inputData, surfaceInput, brdfInput);
//
//     color += surfaceInput.emissionMask * surfaceInput.albedo.rgb;
//
//     
//     //return surfaceInput.albedo;
//     return half4(color, surfaceInput.albedo.a);
//
// }




#endif