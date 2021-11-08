using UnityEditor;
using UnityEngine;

public class PBRShaderGUI : ShaderGUI
{
    public override void OnGUI (MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material target = materialEditor.target as Material;
        base.OnGUI (materialEditor, properties);
        
        MaterialProperty normal = FindProperty("_BumpMap", properties);
        
        if (normal.textureValue == null)
        {
            target.DisableKeyword("_NORMALMAP");
        }
        else
        {
            target.EnableKeyword("_NORMALMAP");
        }
        
        MaterialProperty metallic = FindProperty("_Mroe", properties);
        if (metallic.textureValue == null)
        {
            target.DisableKeyword("_MROE");
        }
        else
        {
            target.EnableKeyword("_MROE");
        }
        
        MaterialProperty emission = PBRShaderGUI.FindProperty("_Emission", properties);
        MaterialProperty emissionColor = PBRShaderGUI.FindProperty("_EmissionColor", properties);
        EditorGUI.BeginChangeCheck();
        var emissionOn = EditorGUILayout.Toggle("Emission", emission.floatValue == 1);
        if (EditorGUI.EndChangeCheck())
            emission.floatValue = emissionOn ? 1 : 0;
        
        EditorGUI.BeginDisabledGroup(!emissionOn);
        {
            EditorGUI.indentLevel++;
            materialEditor.ShaderProperty(emissionColor, "EmissionColor");
            EditorGUI.indentLevel--;
        }
        EditorGUI.EndDisabledGroup();
        
        if (emission.floatValue == 0)
        {
            target.DisableKeyword("_SIMPLEEMISSION");
        }
        else
        {
            target.EnableKeyword("_SIMPLEEMISSION");
        }
    }
}
