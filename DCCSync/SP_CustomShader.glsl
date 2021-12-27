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

half DirectSpecularBRDF()
{
  
}

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
  float roughness = getRoughness(roughness_tex, inputs.sparse_coord);
  vec3 baseColor = getBaseColor(basecolor_tex, inputs.sparse_coord);
  float metallic = getMetallic(metallic_tex, inputs.sparse_coord);
  float specularLevel = getSpecularLevel(specularlevel_tex, inputs.sparse_coord);
  vec3 diffColor = generateDiffuseColor(baseColor, metallic);
  vec3 specColor = generateSpecularColor(specularLevel, baseColor, metallic);
  // Get detail (ambient occlusion) and global (shadow) occlusion factors
  float occlusion = getAO(inputs.sparse_coord) * getShadowFactor();
  float specOcclusion = specularOcclusionCorrection(occlusion, metallic, roughness);
  
  lightRotation -= vec3(180);
  vec3 lightAngles = vec3(lightRotation.x * 0.0174533, (180.0 + lightRotation.y) * 0.0174533, lightRotation.z * 0.0174533); // Degree to radian
  vec3 lightDir = MakeRotation(lightAngles) * vec3(0, 0, 1);
  
  //URP直接省了F项用F0(0.04)代替了
  vec3 F = vec3(0.04,0.04,0.04);
  vec3 kd = (1 - F) * (1 - metallic);
  
  //SH光照
  vec3 envSH = envIrradiance(vectors.normal);
  ///////////////////////////////////Indirect light
  vec3 indirectDiffuse  = occlusion * envSH * baseColor * kd;
  //间接高光因为没办法拿到和unity一样预处理的环境光照mipmap，只能用SP自带的了，效果会比unity的好一点
  vec3 indirectSpecular = specOcclusion * pbrComputeSpecular(vectors, specColor, roughness);
  
  //////////////////////////////////Directional light
  //lambert漫反射，至于问什么这么短看笔记
  vec3 diffuse = baseColor * kd;
  //由于金属非金属间F0存在差异，所以用一个lerp来统一具体看笔记
  vec3 F0 = mix(vec3(0.04, 0.04, 0.04), baseColor, metallic);
  vec3 specular = F0 * 
  
  LocalVectors vectors = computeLocalFrame(inputs);

  // Feed parameters for a physically based BRDF integration
  emissiveColorOutput(pbrComputeEmissive(emissive_tex, inputs.sparse_coord));
  albedoOutput(diffColor);
  diffuseShadingOutput(occlusion * envIrradiance(vectors.normal));
  specularShadingOutput(specOcclusion * pbrComputeSpecular(vectors, specColor, roughness));
  sssCoefficientsOutput(getSSSCoefficients(inputs.sparse_coord));
  sssColorOutput(getSSSColor(inputs.sparse_coord));
}
