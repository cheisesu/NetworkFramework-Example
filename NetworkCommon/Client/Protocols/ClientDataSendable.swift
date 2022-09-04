import Foundation

public protocol ClientDataSendable: AnyObject {
    func send(_ message: Message<ClientCommand>, completion: @escaping (Error?) -> Void)
    func send(_ message: Message<ClientCommand>) async throws
}

extension ClientDataSendable {
    public func send(_ message: Message<ClientCommand>) {
        send(message, completion: { _ in })
    }
}
