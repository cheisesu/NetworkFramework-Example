import Foundation

public enum ProtocolError: LocalizedError {
    case noContent
    case unknownCommand
    case wrongContent(Error)
    case unexpectedCommand
    case connectionNotExists
    case incorrectClientId
    case clientUnavailable

    public var errorDescription: String? {
        switch self {
        case .noContent: return "Content expected"
        case .unknownCommand: return "Unknown command"
        case .wrongContent(let error): return "Wrong content structure '\(error.localizedDescription)'"
        case .unexpectedCommand: return "Another command expected"
        case .connectionNotExists: return "FATAL: Connection has been deleted"
        case .incorrectClientId: return "Passed client's id doesn't match"
        case .clientUnavailable: return "Client is not available or doesn't exist"
        }
    }
}
