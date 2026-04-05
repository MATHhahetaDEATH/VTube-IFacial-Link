using System;
using System.IO;
using System.Text.Json;

namespace VTubeLink
{
    public class Config
    {
        public string IpAddress { get; set; } = string.Empty;
        public string VtsToken { get; set; } = string.Empty;
    }

    public class ConfigManager
    {
        private static ConfigManager? _instance;
        public static ConfigManager Instance => _instance ??= new ConfigManager();

        private Config _config = new();
        private readonly string _configFilePath;

        public string IpAddress
        {
            get => _config.IpAddress;
            set => _config.IpAddress = value;
        }

        public string VtsToken
        {
            get => _config.VtsToken;
            set => _config.VtsToken = value;
        }

        private ConfigManager()
        {
            var appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            var folder = Path.Combine(appData, "VTubeLinkWindows");
            Directory.CreateDirectory(folder);
            _configFilePath = Path.Combine(folder, "config.json");
            Load();
        }

        public void Load()
        {
            try
            {
                if (File.Exists(_configFilePath))
                {
                    var json = File.ReadAllText(_configFilePath);
                    var config = JsonSerializer.Deserialize<Config>(json);
                    if (config != null)
                    {
                        _config = config;
                    }
                }
            }
            catch { }
        }

        public void Save()
        {
            try
            {
                var json = JsonSerializer.Serialize(_config, new JsonSerializerOptions { WriteIndented = true });
                File.WriteAllText(_configFilePath, json);
            }
            catch { }
        }
    }
}
