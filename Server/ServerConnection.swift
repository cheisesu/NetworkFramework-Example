import Foundation
import Network
import NetworkCommon

final class ServerConnection {
    private let queue: DispatchQueue

    var messagesHandler: ServerMessagesHandler?
    let connection: NWConnection
    let id: UUID
    private(set) var details: ConnectionDetails?
    var onClose: (() -> Void)?

    init(_ connection: NWConnection) {
        self.connection = connection
        id = UUID()
        queue = DispatchQueue(label: "com.queue.server_connection.\(id)")
    }

    deinit {
        print("DEINIT \(self) \(id)")
    }

    func set(_ details: ConnectionDetails) {
        self.details = details
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            self?.handleNewState(state)
        }
        connection.start(queue: queue)
    }

    func stop() {
        send(Message(command: .closed, content: nil), completion: { error in
            print("STOP ERROR: \(error)")
        })
    }

    private func handleNewState(_ newState: NWConnection.State) {
        print("server connection new state \(newState)")
        switch newState {
        case .setup: break
        case let .waiting(error):
            print("STATE ERROR: \(error)")
            connection.cancel()
        case .preparing: break
        case .ready:
            configureReceive()
            let content = try! JSONEncoder().encode(id)
            let message = Message(command: ServerCommand.hello, content: content)
            send(message)
        case let .failed(error):
            print("STATE ERROR: \(error)")
            connection.cancel()
        case .cancelled:
            onClose?()
        @unknown default: break
        }
    }

    private func configureReceive() {
        connection.receive(minimumIncompleteLength: 1,
                           maximumLength: .max) { [weak self] content, contentContext, isComplete, error in
            let metadata = contentContext?.protocolMetadata(definition: NWProtocolFramer.Definition.server) as? NWProtocolFramer.Message
            
            if isComplete {
//                self?.connection.cancel()
                return
            } else if let error = error ?? (metadata?["error"] as? Error) {
                self?.send(.error(error))
            } else if let message = metadata?["message"] as? Message<ClientCommand> {
                self?.messagesHandler?.handle(message)
            } else {
                let message = Message.error(ProtocolError.noContent)
                self?.send(message)
            }
            self?.configureReceive()
        }
    }
}

extension ServerConnection: ServerDataSendable {
    func send(_ message: Message<ServerCommand>, completion: @escaping (Error?) -> Void) {
        let metadata = NWProtocolFramer.Message(definition: .server)
        metadata["message"] = message

        let context = NWConnection.ContentContext(identifier: message.command.rawValue,
                                                  isFinal: false,
                                                  metadata: [metadata])
        connection.send(content: nil, contentContext: context, isComplete: true, completion: .contentProcessed({ [weak self] error in
            if let error = error {
                completion(error)
                return
            }
            if message.command == .closed {
                self?.sendFinal(completion: completion)
            } else {
                completion(nil)
            }
        }))
    }

    func send(_ message: Message<ServerCommand>) async throws {
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

    private func sendFinal(completion: @escaping (Error?) -> Void) {
        let context = NWConnection.ContentContext.finalMessage
        connection.send(content: nil, contentContext: context, isComplete: true, completion: .contentProcessed({ [weak connection] error in
            completion(error)
            connection?.cancel()
        }))
    }
}
