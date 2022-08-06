import Foundation

/// Command that a client sends to the server
public enum ClientCommand: String, Codable {
    case hello = "HELLO"
    case clients = "CLIENTS"
    case close = "CLOSE"
    case message = "MESSAGE"
}

extension ClientCommand {
    public var visibility: CommandVisibility {
        switch self {
        case .hello: return .onlyGroup
        case .close: return .global
        case .clients: return .regular
        case .message: return .regular
        }
    }
}
