import Foundation

public struct ServerContentError: Codable {
    public let message: String

    init(_ error: Error) {
        message = error.localizedDescription
    }
}
