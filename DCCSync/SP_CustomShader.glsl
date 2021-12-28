//sp的glsl库
import lib-sss.glsl
import lib-pbr.glsl
import lib-emissive.glsl
import lib-pom.glsl
import lib-utils.glsl

//- Declare the iray mdl material to use with this shader.
//: metadata {
//:   "mdl":"mdl::alg::materials::skin_metallic_roughness::skin_metallic_roughness"
//: }


//- Channels needed for metal/rough workflow are bound here.
//: param auto channel_basecolor
uniform SamplerSparse basecolor_tex;
//: param auto channel_roughness
uniform SamplerSparse roughness_tex;
//: param auto channel_metallic
uniform SamplerSparse metallic_tex;
//: param auto channel_specularlevel
uniform SamplerSparse specularlevel_tex;

//: param custom { "default": [45,45,45], "label": "Directional Rotation", "min": 0, "max": 360 }
uniform vec3 lightRotation;
//: param custom { "default": 1, "label": "LightColor", "widget": "color" }
uniform vec4 lightColor;

mat3 MakeRotation(vec3 angles)
{
  mat3 rx = mat3(
    1, 0, 0, 
    0, cos(angles.x), -sin(angles.x), 
    0, sin(angles.x), cos(angles.x));
  mat3 ry = mat3(
    cos(angles.y), 0, sin(angles.y),
    0, 1, 0,
    -sin(angles.y), 0, cos(angles.y));
  mat3 rz = mat3(
    cos(angles.z), -sin(angles.z), 0,
    sin(angles.z), cos(angles.z), 0, 
    0, 0, 1);
  // Match Unity rotations order: Z axis, X axis, and Y axis (from right to left)
  return ry * rx * rz;
}

//- Shader entry point.
void shade(V2F inputs)
{
    // Apply parallax occlusion mapping if possible
    vec3 viewTS = worldSpaceToTangentSpace(getEyeVec(inputs.position), inputs);
    applyParallaxOffset(inputs, viewTS);
  
    // Fetch material parameters, and conversion to the specular/roughness model
    float roughnessSP = getRoughness(roughness_tex, inputs.sparse_coord);
    vec3 baseColor = getBaseColor(basecolor_tex, inputs.sparse_coord);
    float metallic = getMetallic(metallic_tex, inputs.sparse_coord);
    float specularLevel = getSpecularLevel(specularlevel_tex, inputs.sparse_coord);
    vec3 diffColor = generateDiffuseColor(baseColor, metallic);
    vec3 specColor = generateSpecularColor(specularLevel, baseColor, metallic);
    // Get detail (ambient occlusion) and global (shadow) occlusion factors
    float occlusion = getAO(inputs.sparse_coord) * getShadowFactor();
    float specOcclusion = specularOcclusionCorrection(occlusion, metallic, roughnessSP);
    //SP存储向量信息的结构，见lib-vectors.glsl
    LocalVectors vectors = computeLocalFrame(inputs);
    
    vec3 lightRotation180 = lightRotation - vec3(180);
    vec3 lightAngles = vec3(lightRotation180.x * 0.0174533, (180.0 + lightRotation180.y) * 0.0174533, lightRotation180.z * 0.0174533); // Degree to radian
    vec3 lightDir = MakeRotation(lightAngles) * vec3(0, 0, 1);
    
    //URP直接省了F项用F0(0.04)代替了
    vec3 F = vec3(0.04,0.04,0.04);
    vec3 kd = (1 - F) * (1 - metallic);
    
    //SH光照
    vec3 envSH = envIrradiance(vectors.normal);
    //////////////////////////////////////////////////////////////Indirect light
    vec3 indirectDiffuse  = occlusion * envSH * baseColor * kd;
    //间接高光因为没办法拿到和unity一样预处理的环境光照mipmap，只能用SP自带的了，效果会比unity的好一点
    vec3 indirectSpecular = specOcclusion * pbrComputeSpecular(vectors, specColor, roughnessSP);
    
    /////////////////////////////////////////////////////////////Directional light diffuse
    //lambert漫反射，至于问什么这么短看笔记
    vec3 diffuse = baseColor * kd;
    
    ////////////////////////////////////////////////////////////Directional light specular BRDF
    //roughness平方是因为据Epic所言，这样更好
    float roughness = max(roughnessSP * roughnessSP, 0.0078125);
    float roughness2 = max(roughness * roughness, 6.103515625e-5);
    float roughness2MinusOne = roughness2 - 1;
    float normalizationTerm = roughness * 4.0 + 2.0;
    
    vec3 viewDir = vectors.eye;
    vec3 normalDir = vectors.normal;
    vec3 halfDir = normalize(lightDir + viewDir);
    float NoH = clamp(dot(normalDir, halfDir), 0, 1);
    float LoH = clamp(dot(lightDir, halfDir), 0, 1);
    float d = NoH * NoH * roughness2MinusOne + 1.00001f;

    float LoH2 = LoH * LoH;
    float specularTerm = roughness2 / ((d * d) * max(0.1, LoH2) * normalizationTerm);
    
    ///////////////////////////////////////////////////////////Directional light specular
    //由于金属非金属间F0存在差异，所以用一个lerp来统一具体看笔记
    //这一步lerp(mix)之后实际上已经决定了specular的颜色,具体看笔记
    vec3 specularColor = mix(vec3(0.04, 0.04, 0.04), baseColor, metallic);
    //URP直接光F项"优化"掉了，没了，所以这里看起来会有点奇怪，具体看笔记
    vec3 specular = specularColor * specularTerm;
    
    ///////////////////////////////////////////////////////////final out irradiance
    vec3 emission = pbrComputeEmissive(emissive_tex, inputs.sparse_coord);
    float NoL = clamp(dot(normalDir, lightDir), 0, 1);
    //emm好像没找到距离衰减，默认为1吧
    vec3 radiance = lightColor.xyz * lightColor.w * NoL * 1;
    vec3 col = indirectDiffuse + indirectSpecular + (diffuse + specular) * radiance;
    
    
    vec3 finCol = emission + col;
  
    // Feed parameters for a physically based BRDF integration
    //emissiveColorOutput(pbrComputeEmissive(emissive_tex, inputs.sparse_coord));
    //albedoOutput(diffColor);
    diffuseShadingOutput(finCol);
    //specularShadingOutput(specOcclusion * pbrComputeSpecular(vectors, specColor, roughness));
    //sssCoefficientsOutput(getSSSCoefficients(inputs.sparse_coord));
    //sssColorOutput(getSSSColor(inputs.sparse_coord));
}
