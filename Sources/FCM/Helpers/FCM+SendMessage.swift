import Foundation
import Vapor

extension FCM {
    public func send(_ message: FCMMessageDefault) -> EventLoopFuture<String> {
        _send(message)
    }
    
    public func send(_ message: FCMMessageDefault, on eventLoop: EventLoop) -> EventLoopFuture<String> {
        _send(message).hop(to: eventLoop)
    }
    
    private func _send(_ message: FCMMessageDefault) -> EventLoopFuture<String> {
        guard let configuration = self.configuration else {
            fatalError("FCM not configured. Use app.fcm.configuration = ...")
        }
        if message.apns == nil,
            let apnsDefaultConfig = apnsDefaultConfig {
            message.apns = apnsDefaultConfig
        }
        if message.android == nil,
            let androidDefaultConfig = androidDefaultConfig {
            message.android = androidDefaultConfig
        }
        if message.webpush == nil,
            let webpushDefaultConfig = webpushDefaultConfig {
            message.webpush = webpushDefaultConfig
        }

        let url = actionsBaseURL + configuration.projectId + "/messages:send"
        return getAccessToken().flatMap { accessToken -> EventLoopFuture<ClientResponse> in
            var headers = HTTPHeaders()
            headers.bearerAuthorization = .init(token: accessToken)

            return self.client.post(URI(string: url), headers: headers) { (req) in
                struct Payload: Content {
                    let message: FCMMessageDefault
                }
                let payload = Payload(message: message)
                try req.content.encode(payload)
            }
        }
        .validate()
        .flatMapThrowing { res in
            struct Result: Decodable {
                let name: String
            }
            let result = try res.content.decode(Result.self)
            return result.name
        }
    }
}


extension FCM {
    public  func sendData(_ message: FCMMessageData) -> EventLoopFuture<String> {
        guard let configuration = self.configuration else {
            fatalError("FCM not configured. Use app.fcm.configuration = ...")
        }
        let url = actionsBaseURL + configuration.projectId + "/messages:send"
        return getAccessToken().flatMap { accessToken -> EventLoopFuture<ClientResponse> in
            var headers = HTTPHeaders()
            headers.bearerAuthorization = .init(token: accessToken)
            
            return self.client.post(URI(string: url), headers: headers) { (req) in
                struct Payload: Content {
                    let message: FCMMessageData
                }
                let payload = Payload(message: message)
                try req.content.encode(payload)
            }
        }
        .validate()
        .flatMapThrowing { res in
            struct Result: Decodable {
                let name: String
            }
            let result = try res.content.decode(Result.self)
            return result.name
        }
    }
}

public struct FCMMessageData: Codable {
    let data: [String: String]
    //let token: String
    let content_available: Bool
    let to: String
    public init(data: [String : String], token: String) {
        self.data = data
        //self.token = token
        self.content_available = true
        self.to = token
    }
}
