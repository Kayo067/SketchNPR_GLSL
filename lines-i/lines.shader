Shader "Kayo/Sketch/LinesI"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _LineResolution("Line Resolution", Vector) = (1,1,0,0)
        _LineRange("Line Range", Vector) = (0.25, 0.75, 0, 0)
        _LineRange2("Line Range2", Vector) = (0.5, 0.5, 0, 0)
        _LineScale("Line Scale", float) = 1
        _LineRadius("Line Radius", float) = 1
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        CGINCLUDE

            #include "UnityCG.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed2 _LineResolution;
            fixed2 _LineRange;
            fixed2 _LineRange2;
            fixed _LineScale;
            fixed _LineRadius;
         
            float lines( in float l, in float2 fragCoord, in float2 resolution, in float2 range, in float2 range2, float scale, float radius)
            {
                float2 center = float2(resolution.x/2., resolution.y/2.);
                float2 uv = fragCoord.xy;

                float2 d = uv - center;
                float r = length(d)/1000.;
                float a = atan2(d.y,d.x) + scale*(radius-r)/radius;
                float2 uvt = center+r*float2(cos(a),sin(a));

                float2 uv2 = fragCoord.xy / resolution.xy;
                float c = range2.x + range2.y * sin(uvt.x*1000.);
                float f = smoothstep(range.x*c, range.y*c, l );
                f = smoothstep( 0., .5, f );

                return f;
            }
        ENDCG
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o)
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                float4 sPos = ComputeScreenPos(o.vertex);
                float NdL = dot(v.normal, ObjSpaceLightDir(v.vertex));
                o.color.xy = sPos.xy * _ScreenParams.xy / sPos.w;
                o.color.z = NdL;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float l = i.color.z;
                float darkColor = l;
                float lightColor = 1. - smoothstep(0., .1, l - .5);
                float darkLines = lines(darkColor, i.color.xy, _LineResolution, _LineRange, _LineRange2, _LineScale, _LineRadius);
                float lightLines = lines(lightColor, i.color.xy, _LineResolution, _LineRange, _LineRange2, _LineScale, _LineRadius);
                fixed4 color = tex2D(_MainTex, i.uv) * _Color;
                color.rgb = color.rgb * (.25 + .75 * darkLines) + 1. * (1. - lightLines);
                return color;
            }
            ENDCG
        }
    }
}