import Foundation

public struct ServiceConfig: Codable, Equatable {
    public var ipAddress: String
    public var enableUDP: Bool
    public var enableVTS: Bool
    
    public init(ipAddress: String = "192.168.0.1", enableUDP: Bool = false, enableVTS: Bool = false) {
        self.ipAddress = ipAddress
        self.enableUDP = enableUDP
        self.enableVTS = enableVTS
    }
}

public class ConfigManager {
    public static let shared = ConfigManager()
    
    private let configURL: URL
    
    private init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        self.configURL = homeDir.appendingPathComponent(".vtubelink_config.json")
    }
    
    public func loadConfig() -> ServiceConfig {
        guard let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(ServiceConfig.self, from: data) else {
            return ServiceConfig()
        }
        return config
    }
    
    public func saveConfig(_ config: ServiceConfig) {
        if let data = try? JSONEncoder().encode(config) {
            try? data.write(to: configURL)
        }
    }
}
