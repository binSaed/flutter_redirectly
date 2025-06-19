import Flutter
import UIKit
import Foundation

public class FlutterRedirectlyPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var apiKey: String?
    private var baseUrl: String?
    private var enableDebugLogging: Bool = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_redirectly", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "flutter_redirectly/link_clicks", binaryMessenger: registrar.messenger())
        
        let instance = FlutterRedirectlyPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(call: call, result: result)
        case "createLink":
            createLink(call: call, result: result)
        case "createTempLink":
            createTempLink(call: call, result: result)
        case "getLinks":
            getLinks(result: result)
        case "updateLink":
            updateLink(call: call, result: result)
        case "deleteLink":
            deleteLink(call: call, result: result)
        case "getInitialLink":
            getInitialLink(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let apiKey = args["apiKey"] as? String,
              let baseUrl = args["baseUrl"] as? String else {
            result(FlutterError(code: "INVALID_CONFIG", message: "API key and base URL are required", details: nil))
            return
        }
        
        self.apiKey = apiKey
        self.baseUrl = baseUrl
        self.enableDebugLogging = args["enableDebugLogging"] as? Bool ?? false
        
        if enableDebugLogging {
            print("FlutterRedirectly initialized with baseUrl: \(baseUrl)")
        }
        
        result(nil)
    }
    
    private func createLink(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let slug = args["slug"] as? String,
              let target = args["target"] as? String else {
            result(FlutterError(code: "INVALID_PARAMS", message: "Slug and target are required", details: nil))
            return
        }
        
        var requestBody: [String: Any] = [
            "slug": slug,
            "target": target
        ]
        
        if let metadata = args["metadata"] as? [String: Any] {
            requestBody["metadata"] = metadata
        }
        
        makeApiRequest(method: "POST", endpoint: "/api/v1/links", body: requestBody) { apiResult in
            result(apiResult)
        }
    }
    
    private func createTempLink(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let target = args["target"] as? String else {
            result(FlutterError(code: "INVALID_PARAMS", message: "Target is required", details: nil))
            return
        }
        
        var requestBody: [String: Any] = [
            "target": target,
            "ttlSeconds": args["ttlSeconds"] as? Int ?? 900
        ]
        
        if let slug = args["slug"] as? String {
            requestBody["slug"] = slug
        }
        
        makeApiRequest(method: "POST", endpoint: "/api/v1/temp-links", body: requestBody) { apiResult in
            result(apiResult)
        }
    }
    
    private func getLinks(result: @escaping FlutterResult) {
        makeApiRequest(method: "GET", endpoint: "/api/v1/links", body: nil) { apiResult in
            result(apiResult)
        }
    }
    
    private func updateLink(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let slug = args["slug"] as? String,
              let target = args["target"] as? String else {
            result(FlutterError(code: "INVALID_PARAMS", message: "Slug and target are required", details: nil))
            return
        }
        
        let requestBody: [String: Any] = [
            "target": target
        ]
        
        makeApiRequest(method: "PUT", endpoint: "/api/links/\(slug)", body: requestBody) { apiResult in
            result(apiResult)
        }
    }
    
    private func deleteLink(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let slug = args["slug"] as? String else {
            result(FlutterError(code: "INVALID_PARAMS", message: "Slug is required", details: nil))
            return
        }
        
        makeApiRequest(method: "DELETE", endpoint: "/api/links/\(slug)", body: nil) { apiResult in
            result(apiResult)
        }
    }
    
    private func getInitialLink(result: @escaping FlutterResult) {
        // On iOS, we would typically get the initial URL from application:openURL: or similar
        // For now, returning nil as this would need to be integrated with app delegate
        result(nil)
    }
    
    private func makeApiRequest(method: String, endpoint: String, body: [String: Any]?, completion: @escaping (Any?) -> Void) {
        guard let apiKey = self.apiKey,
              let baseUrl = self.baseUrl,
              let url = URL(string: "\(baseUrl)\(endpoint)") else {
            completion(FlutterError(code: "INVALID_CONFIG", message: "Plugin not properly initialized", details: nil))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        if let body = body, method != "GET" {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } catch {
                completion(FlutterError(code: "SERIALIZATION_ERROR", message: "Failed to serialize request body", details: nil))
                return
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(FlutterError(code: "NETWORK_ERROR", message: "Network error: \(error.localizedDescription)", details: nil))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(FlutterError(code: "INVALID_RESPONSE", message: "Invalid response", details: nil))
                    return
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) } ?? "HTTP \(httpResponse.statusCode)"
                    completion(FlutterError(code: "API_ERROR", message: errorMessage, details: nil))
                    return
                }
                
                guard let data = data else {
                    completion(nil)
                    return
                }
                
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                    completion(jsonObject)
                } catch {
                    completion(FlutterError(code: "PARSE_ERROR", message: "Failed to parse response", details: nil))
                }
            }
        }.resume()
    }
    
    private func isRedirectlyLink(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return host.contains("redirectly.app") || 
               (host.contains("localhost") && url.queryParameters?["user"] != nil)
    }
    
    private func processRedirectlyUrl(_ url: URL) -> [String: Any?] {
        let originalUrl = url.absoluteString
        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        let (username, slug): (String, String)
        
        if host.contains("redirectly.app") {
            // Production URL: username.redirectly.app/slug
            let hostParts = host.components(separatedBy: ".")
            if hostParts.count < 3 || pathComponents.isEmpty {
                return [
                    "originalUrl": originalUrl,
                    "slug": "unknown",
                    "username": "unknown",
                    "error": [
                        "message": "Invalid URL format",
                        "type": 3, // linkResolution
                        "statusCode": NSNull()
                    ],
                    "receivedAt": Int64(Date().timeIntervalSince1970 * 1000)
                ]
            }
            username = hostParts[0]
            slug = pathComponents[0]
        } else if host.contains("localhost"), let userParam = url.queryParameters?["user"] {
            // Development URL: localhost:3000?user=username/slug
            let parts = userParam.components(separatedBy: "/")
            if parts.count != 2 {
                return [
                    "originalUrl": originalUrl,
                    "slug": "unknown",
                    "username": "unknown",
                    "error": [
                        "message": "Invalid development URL format",
                        "type": 3, // linkResolution
                        "statusCode": NSNull()
                    ],
                    "receivedAt": Int64(Date().timeIntervalSince1970 * 1000)
                ]
            }
            username = parts[0]
            slug = parts[1]
        } else {
            return [
                "originalUrl": originalUrl,
                "slug": "unknown",
                "username": "unknown",
                "error": [
                    "message": "Unrecognized URL format",
                    "type": 3, // linkResolution
                    "statusCode": NSNull()
                ],
                "receivedAt": Int64(Date().timeIntervalSince1970 * 1000)
            ]
        }
        
        if enableDebugLogging {
            print("Processing Redirectly link: username=\(username), slug=\(slug)")
        }
        
        return [
            "originalUrl": originalUrl,
            "slug": slug,
            "username": username,
            "linkDetails": NSNull(), // Would need backend endpoint to fetch details
            "error": NSNull(),
            "receivedAt": Int64(Date().timeIntervalSince1970 * 1000)
        ]
    }
    
    // MARK: - FlutterStreamHandler
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

// MARK: - URL Extension

extension URL {
    var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return nil
        }
        
        var parameters: [String: String] = [:]
        for item in queryItems {
            parameters[item.name] = item.value
        }
        return parameters
    }
} 