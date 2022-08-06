import Foundation

/// Command that the server sends to a client
public enum ServerCommand: String, Codable {
    case hello = "HELLO"
    case error = "ERROR"
    case tov = "TOV"
    case clients = "CLIENTS"
    case closed = "CLOSED"
    case message = "MESSAGE"
    case messageSent = "MESSAGE_SENT"
}
