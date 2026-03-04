import Foundation
import SwiftUI

class VTubeStudioManager: ObservableObject {
    @Published var isConnected = false
    @Published var isAuthenticated = false
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let url = URL(string: "ws://127.0.0.1:8001")!
    
    private let pluginName = "VTube-IFacial-Link-Swift"
    private let pluginDeveloper = "xuan25"
    private let apiVersion = "1.0"
    
    private var pendingRequests: [String: CheckedContinuation<[String: Any], Error>] = [:]
    private let queue = DispatchQueue(label: "com.vts.websocket")
    
    func connect() {
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        isConnected = true
        receiveMessageLoop()
        
        Task {
            await authenticateOrRequestToken()
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        DispatchQueue.main.async {
            self.isConnected = false
            self.isAuthenticated = false
        }
        
        // Fail all pending
        queue.async {
            for (_, continuation) in self.pendingRequests {
                continuation.resume(throwing: NSError(domain: "VTS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Disconnected"]))
            }
            self.pendingRequests.removeAll()
        }
    }
    
    // Create a continuous listening loop. Only one `receive` active at a time.
    private func receiveMessageLoop() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self.disconnect()
            case .success(let message):
                self.handleMessage(message)
                self.receiveMessageLoop() // Listen for next
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                // If it's a response to a request, fulfill the continuation
                if let requestID = json["requestID"] as? String {
                    var continuationToFulfill: CheckedContinuation<[String: Any], Error>?
                    queue.sync {
                        continuationToFulfill = self.pendingRequests.removeValue(forKey: requestID)
                    }
                    continuationToFulfill?.resume(returning: json)
                }
            }
        case .data(_):
            break
        @unknown default:
            break
        }
    }
    
    // Send a request and wait for a response with the same requestID
    private func sendRequestAndWait(_ request: [String: Any], requestID: String) async throws -> [String: Any]? {
        let jsonData = try JSONSerialization.data(withJSONObject: request)
        let message = URLSessionWebSocketTask.Message.string(String(data: jsonData, encoding: .utf8)!)
        
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                self.pendingRequests[requestID] = continuation
            }
            
            self.webSocketTask?.send(message) { error in
                if let error = error {
                    self.queue.async {
                        if let removed = self.pendingRequests.removeValue(forKey: requestID) {
                            removed.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }
    
    private func authenticateOrRequestToken() async {
        let tokenKey = "vts_auth_token"
        let savedToken = UserDefaults.standard.string(forKey: tokenKey)
        
        if let token = savedToken {
            print("Found saved token, trying to authenticate...")
            let success = await authenticate(token: token)
            if !success {
                print("Token invalid, requesting new one...")
                if let newToken = await requestToken() {
                    UserDefaults.standard.set(newToken, forKey: tokenKey)
                    let _ = await authenticate(token: newToken)
                }
            }
        } else {
            print("No token found, requesting one...")
            if let newToken = await requestToken() {
                UserDefaults.standard.set(newToken, forKey: tokenKey)
                let _ = await authenticate(token: newToken)
            }
        }
        
        if DispatchQueue.main.sync(execute: { self.isAuthenticated }) {
            await checkAndRegisterParameters()
        }
    }
    
    private func requestToken() async -> String? {
        let reqID = UUID().uuidString
        let request: [String: Any] = [
            "apiName": "VTubeStudioPublicAPI",
            "apiVersion": apiVersion,
            "requestID": reqID,
            "messageType": "AuthenticationTokenRequest",
            "data": [
                "pluginName": pluginName,
                "pluginDeveloper": pluginDeveloper
            ]
        ]
        
        do {
            if let response = try await sendRequestAndWait(request, requestID: reqID),
               let data = response["data"] as? [String: Any],
               let token = data["authenticationToken"] as? String {
                return token
            }
        } catch {
            print("Request token error: \(error)")
        }
        return nil
    }
    
    private func authenticate(token: String) async -> Bool {
        let reqID = UUID().uuidString
        let request: [String: Any] = [
            "apiName": "VTubeStudioPublicAPI",
            "apiVersion": apiVersion,
            "requestID": reqID,
            "messageType": "AuthenticationRequest",
            "data": [
                "pluginName": pluginName,
                "pluginDeveloper": pluginDeveloper,
                "authenticationToken": token
            ]
        ]
        
        do {
            if let response = try await sendRequestAndWait(request, requestID: reqID),
               let data = response["data"] as? [String: Any],
               let authenticated = data["authenticated"] as? Bool {
                DispatchQueue.main.async {
                    self.isAuthenticated = authenticated
                }
                return authenticated
            }
        } catch {
            print("Auth error: \(error)")
        }
        return false
    }
    
    private func checkAndRegisterParameters() async {
        // 1. Fetch parameters
        let fetchReqID = UUID().uuidString
        let request: [String: Any] = [
            "apiName": "VTubeStudioPublicAPI",
            "apiVersion": apiVersion,
            "requestID": fetchReqID,
            "messageType": "InputParameterListRequest"
        ]
        
        var existingCustomParams = Set<String>()
        do {
            if let response = try await sendRequestAndWait(request, requestID: fetchReqID),
               let data = response["data"] as? [String: Any],
               let customParamsArray = data["customParameters"] as? [[String: Any]] {
                for param in customParamsArray {
                    if let name = param["name"] as? String {
                        existingCustomParams.insert(name)
                    }
                }
            }
        } catch {
            print("Fetch params error: \(error)")
        }
        
        // 2. Register missing parameters
        for paramName in Constants.customParams {
            if !existingCustomParams.contains(paramName) {
                let createReqID = UUID().uuidString
                let createReq: [String: Any] = [
                    "apiName": "VTubeStudioPublicAPI",
                    "apiVersion": apiVersion,
                    "requestID": createReqID,
                    "messageType": "ParameterCreationRequest",
                    "data": [
                        "parameterName": paramName,
                        "explanation": "",
                        "min": 0,
                        "max": 1,
                        "defaultValue": 0
                    ]
                ]
                do {
                    _ = try await sendRequestAndWait(createReq, requestID: createReqID)
                } catch {
                    print("Failed to create \(paramName): \(error)")
                }
            }
        }
        print("Parameters registered successfully.")
    }
    
    // Inject parameters continually
    func sendParameters(_ parameters: [VTStudioParam]) {
        guard isConnected && isAuthenticated else { return }
        
        let paramValues = parameters.map { ["id": $0.id, "value": $0.value] }
        
        // Need string UUID or sequential to prevent clash
        // But for high-frequency inject we rarely need an immediate wait. We can just send.
        let request: [String: Any] = [
            "apiName": "VTubeStudioPublicAPI",
            "apiVersion": "1.0",
            "requestID": UUID().uuidString,
            "messageType": "InjectParameterDataRequest",
            "data": [
                "faceFound": true,
                "parameterValues": paramValues
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: request)
            let message = URLSessionWebSocketTask.Message.string(String(data: jsonData, encoding: .utf8)!)
            
            webSocketTask?.send(message) { error in
                if let error = error {
                    print("Error injecting params: \(error)")
                }
            }
        } catch {
            print("JSON serialization error: \(error)")
        }
    }
}
