using System.Collections.Generic;

namespace VTubeLink
{
    public class CapturedData
    {
        public Dictionary<string, float> Blendshapes { get; set; } = new();
        public float HeadRotationX { get; set; }
        public float HeadRotationY { get; set; }
        public float HeadRotationZ { get; set; }
        public float HeadPositionX { get; set; }
        public float HeadPositionY { get; set; }
        public float HeadPositionZ { get; set; }
        public float LeftEyeRotationX { get; set; }
        public float LeftEyeRotationY { get; set; }
        public float LeftEyeRotationZ { get; set; }
        public float RightEyeRotationX { get; set; }
        public float RightEyeRotationY { get; set; }
        public float RightEyeRotationZ { get; set; }
    }

    public class VTStudioParam
    {
        public string Id { get; set; } = string.Empty;
        public float Value { get; set; }
    }

    public class MappingUpdate
    {
        public Dictionary<string, float> ArkitParams { get; set; } = new();
        public Dictionary<string, float> VtsParams { get; set; } = new();
    }
}
