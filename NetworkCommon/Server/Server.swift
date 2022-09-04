import Foundation
import Network

public final class Server {
    public enum Error: Swift.Error {
        /// Wrong port
        case incorrectPort
    }

    private let listener: NWListener
    private let queue: DispatchQueue
    private var waiter: DispatchWorkItem!
    private var connections: [UUID: ServerConnection] = [:]

    public var onError: ((Swift.Error) -> Void)?
    public var onStop: (() -> Void)?
    public var onStart: (() -> Void)?

    public init(_ port: UInt16) throws {
        guard let port = NWEndpoint.Port(rawValue: port) else {
            throw Error.incorrectPort
        }
        let tcp = NWProtocolTCP.Options()
        let ararat = NWProtocolFramer.Options(definition: .server)
        let params = NWParameters(tls: nil, tcp: tcp)
        params.defaultProtocolStack.applicationProtocols.insert(ararat, at: 0)
        params.includePeerToPeer = true
        listener = try NWListener(using: params, on: port)
        listener.service = NWListener.Service(name: "network_server", type: "_network_server._tcp")
        queue = DispatchQueue(label: "com.queue.server")
        waiter = DispatchWorkItem {}
    }

    @available (*, deprecated)
    public func startSync() throws {
        let waiter = DispatchWorkItem {}
        var error: Swift.Error?
        _start { err in
            error = err
        }
        waiter.wait()
        if let error = error {
            throw error
        }
    }

    public func start() {
        _start(completion: { _ in })
    }

    public func stop() {
        listener.cancel()
    }

    private func _start(completion: @escaping (Swift.Error?) -> Void) {
        listener.stateUpdateHandler = { [weak self] state in
            self?.stateDidChange(state, completion: completion)
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }
        listener.serviceRegistrationUpdateHandler = { service in
            print("SERVICE: \(service)")
        }
        listener.start(queue: queue)
    }

    private func stateDidChange(_ newState: NWListener.State,
                                completion: @escaping (Swift.Error?) -> Void) {
        print("new state \(newState)")
        switch newState {
        case .setup: break
        case let .waiting(error):
            completion(error)
            onError?(error)
        case .ready:
            print("ready")
            onStart?()
        case let .failed(error):
            completion(error)
            onError?(error)
        case .cancelled:
            completion(nil)
            onStop?()
        @unknown default: break
        }
    }

    private func handleNewConnection(_ connection: NWConnection) {
        print("new connection \(connection)")
        let serverConnection = ServerConnection(connection)
        let id = serverConnection.id
        serverConnection.messagesHandler = createMessagesHandler(with: serverConnection)
        connections[id] = serverConnection
        serverConnection.onClose = { [weak self] in
            print("CONNECTION CLOSED")
            self?.connections[id] = nil
            self?.broadcastClients()
        }
        serverConnection.start()
    }

    private func createMessagesHandler(with connection: ServerConnection) -> ServerMessagesHandler {
        let helloHandler = HelloServerMessagesHandler(connectionId: connection.id,
                                                      dataSender: connection,
                                                      onClientDetails: { [weak connection] details in
            connection?.set(details)
        }, onFinish: { [weak self] in
            self?.broadcastClients()
        })

        let defaultHandler = DefaultServerMessagesHandler(
            connectionId: connection.id,
            dataSender: connection,
            subhandlers: [helloHandler],
            onClose: { [weak connection] in
                connection?.stop()
            }, getClientsMessage: { [weak self, weak connection] in
                guard let connection = connection else {
                    throw ProtocolError.connectionNotExists
                }
                guard let self = self else {
                    fatalError("Server not exists")
                }
                return try self.clientsMessage(for: connection)
            }, sendMessageToClient: { [weak self] receiverId, message in
                guard let self = self else {
                    fatalError("Server not exists")
                }
                guard let connection = self.connections[receiverId] else {
                    throw ProtocolError.clientUnavailable
                }
                connection.send(message)
            }
        )
        return defaultHandler
    }

    private func broadcastClients() {
        do {
            try connections.forEach { (_, connection) in
                let message = try self.clientsMessage(for: connection)
                connection.send(message)
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    private func clientsMessage(for connection: ServerConnection) throws -> Message<ServerCommand> {
        let clients = connections
            .map { $0.value }
            .filter { $0.id != connection.id }
            .compactMap { $0.details }
        let data = try JSONEncoder().encode(clients)
        return Message(command: ServerCommand.clients, content: data)
    }
}
