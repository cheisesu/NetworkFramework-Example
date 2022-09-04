import Foundation

public protocol ServerDataSendable: AnyObject {
    func send(_ message: Message<ServerCommand>, completion: @escaping (Error?) -> Void)
    func send(_ message: Message<ServerCommand>) async throws
}

extension ServerDataSendable {
    public func send(_ message: Message<ServerCommand>) {
        send(message, completion: { _ in })
    }
}
