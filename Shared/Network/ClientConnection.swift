import Foundation
import Network
import NetworkCommon

final class ClientConnection {
    private let queue: DispatchQueue
    private let queueId: UUID = UUID()

    var messagesHandler: ClientMessagesHandler?
    let connection: NWConnection
    private(set) var details: ConnectionDetails
    var onClose: (() -> Void)?
    var onError: ((Error) -> Void)?
    var onCommunicationError: ((Error) -> Void)?
    var onConnected: (() -> Void)?

    init(_ connection: NWConnection, details: ConnectionDetails) {
        self.connection = connection
        self.details = details
        queue = DispatchQueue(label: "com.queue.client_connection.\(queueId)")
    }

    deinit {
        print("DEINIT \(self) \(details.id)")
    }

    func updateDetails(_ newDetails: ConnectionDetails) {
        details = newDetails
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            self?.handleNewState(state)
        }
        connection.start(queue: queue)
    }

    func stop() {
        send(Message(command: .close, content: nil), completion: { [weak self] error in
            if let error = error {
                self?.onError?(error)
            }
        })
    }

    private func handleNewState(_ newState: NWConnection.State) {
        print("client connection new state \(newState)")
        switch newState {
        case .setup: break
        case let .waiting(error):
            onError?(error)
            connection.cancel()
        case .preparing: break
        case .ready:
            onConnected?()
            configureReceive()
        case let .failed(error):
            onError?(error)
            connection.cancel()
        case .cancelled:
            onClose?()
        @unknown default: break
        }
    }

    private func configureReceive() {
        connection.receive(minimumIncompleteLength: 1,
                           maximumLength: .max) { [weak self] content, contentContext, isComplete, error in
            let metadata = contentContext?.protocolMetadata(definition: NWProtocolFramer.Definition.client) as? NWProtocolFramer.Message
            
            if isComplete {
                self?.connection.cancel()
                return
            } else if let error = error {
                self?.onError?(error)
                return
            } else if let error = metadata?["error"] as? Error {
                self?.onCommunicationError?(error)
            } else if let message = metadata?["message"] as? Message<ServerCommand> {
                self?.messagesHandler?.handle(message)
            } else {
                self?.onCommunicationError?(ProtocolError.noContent)
            }
            self?.configureReceive()
        }
    }
}

extension ClientConnection: ClientDataSendable {
    func send(_ message: Message<ClientCommand>, completion: @escaping (Error?) -> Void) {
        let metadata = NWProtocolFramer.Message(definition: .client)
        metadata["message"] = message

        let context = NWConnection.ContentContext(identifier: message.command.rawValue,
                                                  isFinal: false,
                                                  metadata: [metadata])
        connection.send(content: nil, contentContext: context, isComplete: true, completion: .contentProcessed({ error in
            completion(error)
        }))
    }

    func send(_ message: Message<ClientCommand>) async throws {
        try await withCheckedThrowingContinuation { [weak self] (cont: CheckedContinuation<Void, Error>) in
            self?.send(message, completion: { error in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume()
                }
            })
        }
    }
}
