﻿Shader "Hidden/Ink" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }

    CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        sampler2D _PaperTex;
        float4 _MainTex_TexelSize;
        float _ContrastThreshold;

        struct VertexData {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f {
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
        };

        v2f vp(VertexData v) {
            v2f f;
            f.vertex = UnityObjectToClipPos(v.vertex);
            f.uv = v.uv;
            
            return f;
        }
    ENDCG

    SubShader {
        Cull Off ZWrite Off ZTest Always

        // Edge Detection By Contrast
        Pass {
            CGPROGRAM
            #pragma vertex vp
            #pragma fragment fp

            half SampleLuminance(float2 uv) {
                return LinearRgbToLuminance(tex2D(_MainTex, uv));
            }

            half SampleLuminance(float2 uv, float uOffset, float vOffset) {
                uv += _MainTex_TexelSize * float2(uOffset, vOffset);
                return SampleLuminance(uv);
            }

            fixed4 fp(v2f i) : SV_Target {
                fixed4 col = tex2D(_MainTex, i.uv);

                half m = SampleLuminance(i.uv);
                half n = SampleLuminance(i.uv, 0, 1);
                half e = SampleLuminance(i.uv, 1, 0);
                half s = SampleLuminance(i.uv, 0, -1);
                half w = SampleLuminance(i.uv, -1, 0);
                half highest = max(max(max(max(n, e), s), w), m);
                half lowest = min(min(min(min(n, e), s), w), m);
                half contrast = highest - lowest;
                
                return contrast < _ContrastThreshold ? 1 : 0;
            }

            ENDCG
        }

        // Edge Detection By Sobel-Feldman Operator
        Pass {
            CGPROGRAM
            #pragma vertex vp
            #pragma fragment fp

            fixed4 fp(v2f i) : SV_Target {
                fixed4 col = tex2D(_MainTex, i.uv);
                int x, y;

                int3x3 Kx = {
                    1, 0, -1,
                    2, 0, -2,
                    1, 0, -1
                };

                int3x3 Ky = {
                    1, 2, 1,
                    0, 0, 0,
                    -1, -2, -1
                };

                float Gx = 0.0f;
                float Gy = 0.0f;

                for (x = -1; x <= 1; ++x) {
                    for (y = -1; y <= 1; ++y) {
                        float2 uv = i.uv + _MainTex_TexelSize * float2(x, y);
                        
                        half l = LinearRgbToLuminance(tex2D(_MainTex, uv));
                        Gx += Kx[x + 1][y + 1] * l;
                        Gy += Ky[x + 1][y + 1] * l;
                    }
                }
                
                return sqrt(Gx * Gx + Gy * Gy);
            }

            ENDCG
        }
    }
}
