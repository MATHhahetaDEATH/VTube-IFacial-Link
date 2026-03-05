import Foundation
import VTubeLinkShared

class VTubeStudioManager: ObservableObject {
    @Published var isConnected = false
    @Published var isAuthenticated = false
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let url = URL(string: "ws://127.0.0.1:8001")!
    
    private let pluginName = "VTube-IFacial-Link-Swift"
    private let pluginDeveloper = "xuan25"
    private let apiVersion = "1.0"
    
    // Flag indicating the injection loop is running to avoid duplicate loops
    private var injectionLoopRunning = false
    // Whether reconnection should be attempted on failure
    private var shouldReconnect = false
    
    // Reference to the captured data source (set by the service)
    weak var dataSource: IFacialMocapReceiver?
    
    func connect() {
        shouldReconnect = true
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        DispatchQueue.main.async {
            self.isConnected = true
        }
        
        Task {
            await performInit()
        }
    }
    
    func disconnect() {
        shouldReconnect = false
        injectionLoopRunning = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        DispatchQueue.main.async {
            self.isConnected = false
            self.isAuthenticated = false
        }
    }
    
    private func reconnect() {
        guard shouldReconnect else { return }
        print("Reconnecting in 3 seconds...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self, self.shouldReconnect else { return }
            let session = URLSession(configuration: .default)
            self.webSocketTask = session.webSocketTask(with: self.url)
            self.webSocketTask?.resume()
            self.isConnected = true
            Task {
                await self.performInit()
            }
        }
    }
    
    // Simple send-then-receive helper mirroring Python's `await websocket.send(); await websocket.recv()`
    private func sendAndReceive(_ payload: [String: Any]) async throws -> [String: Any] {
        guard let task = webSocketTask else {
            throw NSError(domain: "VTS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not connected"])
        }
        
        let messageType = payload["messageType"] as? String ?? "unknown"
        
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Send
        print("[VTS] Sending: \(messageType)")
        try await task.send(.string(jsonString))
        print("[VTS] Sent. Waiting for response...")
        
        // Receive the response
        let message = try await task.receive()
        print("[VTS] Received response for: \(messageType)")
        
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return json
            }
            throw NSError(domain: "VTS", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        case .data(_):
            throw NSError(domain: "VTS", code: -3, userInfo: [NSLocalizedDescriptionKey: "Unexpected binary data"])
        @unknown default:
            throw NSError(domain: "VTS", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unknown message type"])
        }
    }
    
    /// Mirrors the Python `vtube.init(websocket)` flow exactly: auth, then register params.
    private func performInit() async {
        do {
            let authSuccess = try await authenticateOrRequestToken()
            if authSuccess {
                try await checkAndRegisterParameters()
                print("[VTS] Successfully initialized. Starting injection loop.")
                await injectionLoop()
            } else {
                print("[VTS] Authentication failed. Not starting injection.")
            }
        } catch {
            print("Init failed: \(error)")
            // Clean up the broken connection and try again
            webSocketTask?.cancel(with: .goingAway, reason: nil)
            webSocketTask = nil
            DispatchQueue.main.async {
                self.isConnected = false
                self.isAuthenticated = false
            }
            reconnect()
        }
    }
    
    private func authenticateOrRequestToken() async throws -> Bool {
        let tokenKey = "vts_auth_token"
        let savedToken = UserDefaults.standard.string(forKey: tokenKey)
        
        var success = false
        
        if let token = savedToken, !token.isEmpty {
            print("[VTS] Found saved token, trying to authenticate...")
            success = try await authenticate(token: token)
            if !success {
                print("[VTS] Token invalid, clearing and requesting new one...")
                UserDefaults.standard.removeObject(forKey: tokenKey)
                let newToken = try await requestToken()
                UserDefaults.standard.set(newToken, forKey: tokenKey)
                success = try await authenticate(token: newToken)
            }
        } else {
            print("[VTS] No token found, requesting one...")
            let newToken = try await requestToken()
            UserDefaults.standard.set(newToken, forKey: tokenKey)
            success = try await authenticate(token: newToken)
        }
        
        return success
    }
    
    private func requestToken() async throws -> String {
        let payload: [String: Any] = [
            "apiName": "VTubeStudioPublicAPI",
            "apiVersion": apiVersion,
            "requestID": UUID().uuidString,
            "messageType": "AuthenticationTokenRequest",
            "data": [
                "pluginName": pluginName,
                "pluginDeveloper": pluginDeveloper
            ]
        ]
        
        let response = try await sendAndReceive(payload)
        guard let data = response["data"] as? [String: Any],
              let token = data["authenticationToken"] as? String else {
            throw NSError(domain: "VTS", code: -10, userInfo: [NSLocalizedDescriptionKey: "No token in response"])
        }
        return token
    }
    
    private func authenticate(token: String) async throws -> Bool {
        let payload: [String: Any] = [
            "apiName": "VTubeStudioPublicAPI",
            "apiVersion": apiVersion,
            "requestID": UUID().uuidString,
            "messageType": "AuthenticationRequest",
            "data": [
                "pluginName": pluginName,
                "pluginDeveloper": pluginDeveloper,
                "authenticationToken": token
            ]
        ]
        
        let response = try await sendAndReceive(payload)
        if let data = response["data"] as? [String: Any],
           let authenticated = data["authenticated"] as? Bool {
            DispatchQueue.main.async {
                self.isAuthenticated = authenticated
            }
            return authenticated
        }
        return false
    }
    
    private func checkAndRegisterParameters() async throws {
        // 1. Fetch existing parameters
        let fetchPayload: [String: Any] = [
            "apiName": "VTubeStudioPublicAPI",
            "apiVersion": apiVersion,
            "requestID": UUID().uuidString,
            "messageType": "InputParameterListRequest"
        ]
        
        var existingCustomParams = Set<String>()
        let fetchResponse = try await sendAndReceive(fetchPayload)
        if let data = fetchResponse["data"] as? [String: Any],
           let customParamsArray = data["customParameters"] as? [[String: Any]] {
            for param in customParamsArray {
                if let name = param["name"] as? String {
                    existingCustomParams.insert(name)
                }
            }
        }
        
        // 2. Register missing parameters
        for paramName in Constants.customParams {
            if !existingCustomParams.contains(paramName) {
                let createPayload: [String: Any] = [
                    "apiName": "VTubeStudioPublicAPI",
                    "apiVersion": apiVersion,
                    "requestID": UUID().uuidString,
                    "messageType": "ParameterCreationRequest",
                    "data": [
                        "parameterName": paramName,
                        "explanation": "",
                        "min": 0,
                        "max": 1,
                        "defaultValue": 0
                    ]
                ]
                _ = try await sendAndReceive(createPayload)
            }
        }
        print("Parameters registered successfully.")
    }
    
    /// Mirrors the Python PluginThread.run_loop() exactly:
    /// ```python
    /// while not self.should_terminate:
    ///     ifacial_data = self.capture_data.read_data()
    ///     parameter_values = build_params_dict(ifacial_data)
    ///     pack = await vtube.inject_params(websocket, parameter_values)
    /// ```
    /// Single-threaded: send → wait for response → repeat. No concurrent operations.
    private func injectionLoop() async {
        injectionLoopRunning = true
        
        while injectionLoopRunning && isConnected && isAuthenticated {
            guard let source = dataSource else {
                // No data source yet; wait a bit
                try? await Task.sleep(nanoseconds: 16_000_000) // 16ms
                continue
            }
            
            let capturedData = source.latestData
            let params = DataMapper.buildParamsDict(from: capturedData)
            
            let paramValues: [[String: Any]] = params.map { ["id": $0.id, "value": $0.value as Any] }
            
            let payload: [String: Any] = [
                "apiName": "VTubeStudioPublicAPI",
                "apiVersion": "1.0",
                "requestID": UUID().uuidString,
                "messageType": "InjectParameterDataRequest",
                "data": [
                    "faceFound": true,
                    "parameterValues": paramValues
                ] as [String : Any]
            ]
            
            do {
                _ = try await sendAndReceive(payload)
            } catch {
                print("Injection error: \(error)")
                break
            }
        }
        
        print("Injection loop ended.")
        injectionLoopRunning = false
        
        // If we broke out due to an error and we should still be running, reconnect
        if shouldReconnect {
            webSocketTask?.cancel(with: .goingAway, reason: nil)
            webSocketTask = nil
            DispatchQueue.main.async {
                self.isConnected = false
                self.isAuthenticated = false
            }
            reconnect()
        }
    }
}
