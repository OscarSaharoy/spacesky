// Oscar Saharoy 2020
// stars code by n-yoda

Shader "Custom/SpaceSky" {

    Properties {

        [Header(Sun)]
        _SunSize ("Sun Size", Range(0,1)) = 0.04
        _BoostSun ("Boost Sun", Range(0, 10)) = 1
        _SunTex ("Sun Texture", 2D) = "white" {}

        [Header(Stars)]
        [Toggle] _Stars ("Stars", Int) = 1
        _StarsSize ("Stars Size", Range(0,0.1)) = 0.009
        _StarsDensity ("Stars Density", Range(0,1)) = 0.02
        _StarsHash ("Stars Hash", Vector) = (641, -113, 271, 1117)

    }

    SubShader {

        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off ZWrite Off

        Pass {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            uniform half _SunSize;
            uniform half _StarsDensity;
            uniform half _StarsSize;
            uniform half4 _StarsHash;
            uniform half _BoostSun;
            sampler2D _SunTex;

            struct appdata_t {

                float4 vertex : POSITION;
            };

            struct v2f {

                float4  pos             : SV_POSITION;
                half3   vertex          : TEXCOORD0;
            };

            v2f vert (appdata_t v) {

                v2f OUT;
                OUT.pos = UnityObjectToClipPos(v.vertex);
                OUT.vertex = -v.vertex;

                return OUT;
            }

            half4 frag (v2f IN) : SV_Target {

                // initialise colour
                half3 col   = half3(0.0, 0.0, 0.0);

                // setup view and light directions
                half3 ray   = normalize(mul((float3x3)unity_ObjectToWorld, IN.vertex));
                half eyeCos = - dot(_WorldSpaceLightPos0.xyz, ray);

                // overall radial gradient
                half x = pow((1-eyeCos)*500, 0.5); //pow((1-eyeCos)*3000, 0.5);

                half r = 1.7 * pow(1.16, -x*2); // 1.5 * pow(1.16, -x);
                half g = 1.7 * pow(1.08, -x*2); // 1.5 * pow(1.08, -x);
                half b = 1.7 * pow(1.03, -x*2); // 1.5 * pow(1.03, -x);

                col += half3(r, g, b);

                // light spikes
                half3 delta = _WorldSpaceLightPos0 + ray;
                half theta  = atan2(delta.y, delta.z);
                half radius = length(delta);

                half spike = pow(cos(12*theta) * cos(10*theta), 2);
                col += clamp(spike / ((radius+1)*10) * saturate((1.414-radius)), 0, 3);

                // stars by n-yoda
                half3 pos = ray / _StarsSize;
                half3 center = round(pos);
                half hash = dot(_StarsHash.xyz, center) % _StarsHash.w;
                half threshold = _StarsHash.w * _StarsDensity;

                if (abs(hash) < threshold) {

                    half dist = length(pos - center);
                    half star = pow(saturate(0.5 - dist * dist) * 2, 14);
                    col += star;
                }

                // output colour
                return half4(col, 1.0);
            }

            ENDCG
        }
    }

    Fallback Off

}