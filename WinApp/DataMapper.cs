using System;
using System.Collections.Generic;

namespace VTubeLink
{
    public static class DataMapper
    {
        public static List<VTStudioParam> BuildParamsDict(CapturedData data)
        {
            var parameters = new List<VTStudioParam>();
            var blendshapes = data.Blendshapes;

            float Bs(string key) => blendshapes.TryGetValue(key, out var val) ? val : 0f;

            // VTubeStudio Default
            parameters.Add(new VTStudioParam { Id = "FacePositionX", Value = data.HeadPositionX * Constants.FacePositionXRatio });
            parameters.Add(new VTStudioParam { Id = "FacePositionY", Value = data.HeadPositionY * Constants.FacePositionYRatio });
            parameters.Add(new VTStudioParam { Id = "FacePositionZ", Value = -data.HeadPositionZ * Constants.FacePositionZRatio });

            parameters.Add(new VTStudioParam { Id = "FaceAngleX", Value = data.HeadRotationY * Constants.FaceAngleXRatio });
            parameters.Add(new VTStudioParam { Id = "FaceAngleY", Value = -data.HeadRotationX * Constants.FaceAngleYRatio });
            parameters.Add(new VTStudioParam { Id = "FaceAngleZ", Value = -data.HeadRotationZ * Constants.FaceAngleZRatio });

            float mouthSmileLeft = Bs("mouthSmile_L");
            float mouthSmileRight = Bs("mouthSmile_R");
            float mouthShrugLower = Bs("mouthShrugLower");
            float browDownLeft = Bs("browDown_L");
            float browDownRight = Bs("browDown_R");
            float jawOpen = Bs("jawOpen");
            float mouthClose = Bs("mouthClose");

            float smileInner1 = Math.Max(mouthSmileLeft + mouthSmileRight - 0.2f, 0.0f);
            float smileInner2 = (float)Math.Pow(Math.Max(mouthShrugLower - 0.4f, 0.0f), 1.0f) * 1.0f;
            float browDownAvg = (browDownLeft + browDownRight) / 2.0f;
            float mouthOpenFactor = (jawOpen - mouthClose) * 0.15f;
            float smileInner3 = (float)Math.Pow(Math.Max(browDownAvg - 0.3f + (0.08f + mouthOpenFactor), 0.0f), 0.4f) * 1.5f;

            float mouthSmileVal = ((smileInner1 - smileInner2 - smileInner3) * Constants.MouthSmileRatio) / 2.0f + 0.5f;
            parameters.Add(new VTStudioParam { Id = "MouthSmile", Value = mouthSmileVal });

            parameters.Add(new VTStudioParam { Id = "MouthOpen", Value = (jawOpen - mouthClose) * Constants.MouseOpenRatio });
            parameters.Add(new VTStudioParam { Id = "Brows", Value = Bs("browInnerUp") * Constants.BrowsRatio });

            float tongueOut = Bs("tongueOut");
            parameters.Add(new VTStudioParam { Id = "TongueOut", Value = tongueOut < Constants.TongueOutRatio ? 0.0f : 1.0f });

            float eyeOpenLeft = (1.0f - Bs("eyeBlink_L")) * Constants.EyeOpenRatio - (Constants.EyeOpenRatio - 1.0f);
            parameters.Add(new VTStudioParam { Id = "EyeOpenLeft", Value = eyeOpenLeft });

            float eyeOpenRight = (1.0f - Bs("eyeBlink_R")) * Constants.EyeOpenRatio - (Constants.EyeOpenRatio - 1.0f);
            parameters.Add(new VTStudioParam { Id = "EyeOpenRight", Value = eyeOpenRight });

            parameters.Add(new VTStudioParam { Id = "EyeLeftX", Value = (Bs("eyeLookIn_L") - Bs("eyeLookOut_L")) * Constants.EyeRotationRatio });
            parameters.Add(new VTStudioParam { Id = "EyeLeftY", Value = (Bs("eyeLookUp_L") - Bs("eyeLookDown_L")) * Constants.EyeRotationRatio });
            parameters.Add(new VTStudioParam { Id = "EyeRightX", Value = (Bs("eyeLookOut_R") - Bs("eyeLookIn_R")) * Constants.EyeRotationRatio });
            parameters.Add(new VTStudioParam { Id = "EyeRightY", Value = (Bs("eyeLookUp_R") - Bs("eyeLookDown_R")) * Constants.EyeRotationRatio });

            parameters.Add(new VTStudioParam { Id = "CheekPuff", Value = Bs("cheekPuff") * Constants.CheekPuffRatio });

            float mouthRollLower = Bs("mouthRollLower");
            parameters.Add(new VTStudioParam { Id = "FaceAngry", Value = (mouthRollLower * mouthShrugLower) < Constants.FaceAngryRatio ? 0.0f : 1.0f });

            float browOuterUpLeft = Bs("browOuterUp_L");
            parameters.Add(new VTStudioParam { Id = "BrowLeftY", Value = ((browOuterUpLeft - browDownLeft) * Constants.BrowRightYRatio + 1.0f) / 2.0f });

            float browOuterUpRight = Bs("browOuterUp_R");
            parameters.Add(new VTStudioParam { Id = "BrowRightY", Value = ((browOuterUpRight - browDownRight) * Constants.BrowRightYRatio + 1.0f) / 2.0f });

            parameters.Add(new VTStudioParam { Id = "MouthX", Value = (Bs("mouthLeft") - Bs("mouthRight")) * Constants.MouthXRatio });

            // Custom Params (ARKit) mapped from blendshapes 1-1 to customParams names
            var nameMappings = new Dictionary<string, string>
            {
                { "EyeBlinkLeft", "eyeBlink_L" }, { "EyeLookDownLeft", "eyeLookDown_L" }, { "EyeLookInLeft", "eyeLookIn_L" },
                { "EyeLookOutLeft", "eyeLookOut_L" }, { "EyeLookUpLeft", "eyeLookUp_L" }, { "EyeSquintLeft", "eyeSquint_L" },
                { "EyeWideLeft", "eyeWide_L" }, { "EyeBlinkRight", "eyeBlink_R" }, { "EyeLookDownRight", "eyeLookDown_R" },
                { "EyeLookInRight", "eyeLookIn_R" }, { "EyeLookOutRight", "eyeLookOut_R" }, { "EyeLookUpRight", "eyeLookUp_R" },
                { "EyeSquintRight", "eyeSquint_R" }, { "EyeWideRight", "eyeWide_R" }, { "JawForward", "jawForward" },
                { "JawLeft", "jawLeft" }, { "JawRight", "jawRight" }, { "JawOpen", "jawOpen" }, { "MouthClose", "mouthClose" },
                { "MouthFunnel", "mouthFunnel" }, { "MouthPucker", "mouthPucker" }, { "MouthLeft", "mouthLeft" }, { "MouthRight", "mouthRight" },
                { "MouthSmileLeft", "mouthSmile_L" }, { "MouthSmileRight", "mouthSmile_R" }, { "MouthFrownLeft", "mouthFrown_L" },
                { "MouthFrownRight", "mouthFrown_R" }, { "MouthDimpleLeft", "mouthDimple_L" }, { "MouthDimpleRight", "mouthDimple_R" },
                { "MouthStretchLeft", "mouthStretch_L" }, { "MouthStretchRight", "mouthStretch_R" }, { "MouthRollLower", "mouthRollLower" },
                { "MouthRollUpper", "mouthRollUpper" }, { "MouthShrugLower", "mouthShrugLower" }, { "MouthShrugUpper", "mouthShrugUpper" },
                { "MouthPressLeft", "mouthPress_L" }, { "MouthPressRight", "mouthPress_R" }, { "MouthLowerDownLeft", "mouthLowerDown_L" },
                { "MouthLowerDownRight", "mouthLowerDown_R" }, { "MouthUpperUpLeft", "mouthUpperUp_L" }, { "MouthUpperUpRight", "mouthUpperUp_R" },
                { "BrowDownLeft", "browDown_L" }, { "BrowDownRight", "browDown_R" }, { "BrowInnerUp", "browInnerUp" },
                { "BrowOuterUpLeft", "browOuterUp_L" }, { "BrowOuterUpRight", "browOuterUp_R" }, { "CheekPuff", "cheekPuff" },
                { "CheekSquintLeft", "cheekSquint_L" }, { "CheekSquintRight", "cheekSquint_R" }, { "NoseSneerLeft", "noseSneer_L" },
                { "NoseSneerRight", "noseSneer_R" }, { "TongueOut", "tongueOut" }
            };

            foreach (var customParam in Constants.CustomParams)
            {
                if (nameMappings.TryGetValue(customParam, out var mappedKey))
                {
                    parameters.Add(new VTStudioParam { Id = customParam, Value = Bs(mappedKey) });
                }
                else
                {
                    parameters.Add(new VTStudioParam { Id = customParam, Value = 0.0f });
                }
            }

            return parameters;
        }
    }
}
