import Foundation
import Network

public final class Client {
    private let connection: ClientConnection
    private let endpoint: NWEndpoint
    private var details: ConnectionDetails

    public var id: UUID {
        details.id
    }

    public var onError: ((Error) -> Void)? {
        get { connection.onError }
        set { connection.onError = newValue}
    }
    public var onClose: (() -> Void)? {
        get { connection.onClose }
        set { connection.onClose = newValue}
    }
    public var onCommunicationError: ((Error) -> Void)? {
        get { connection.onCommunicationError }
        set { connection.onCommunicationError = newValue}
    }
    public var onConnected: (() -> Void)? {
        get { connection.onConnected }
        set { connection.onConnected = newValue}
    }

    public var onUpdateDetails: ((ConnectionDetails) -> Void)?
    public var onUpdateClients: (([ConnectionDetails]) -> Void)?
    public var onReceivedLetter: ((Letter) -> Void)?
    public var onOutLetterSent: ((Letter) -> Void)?

    public convenience init(_ address: String, details: ConnectionDetails) {
        let host = NWEndpoint.Host(address)
        let port = NWEndpoint.Port(integerLiteral: defaultPort)
        let endpoint = NWEndpoint.hostPort(host: host, port: port)

        self.init(endpoint, details: details)
    }

    public init(_ endpoint: NWEndpoint, details: ConnectionDetails) {
        self.endpoint = endpoint
        self.details = details
        let tcp = NWProtocolTCP.Options()
        let ararat = NWProtocolFramer.Options(definition: .client)
        let params = NWParameters(tls: nil, tcp: tcp)
        params.defaultProtocolStack.applicationProtocols.insert(ararat, at: 0)
        params.includePeerToPeer = true
        let connection = NWConnection(to: endpoint, using: params)
        self.connection = ClientConnection(connection, details: details)

        self.connection.messagesHandler = createMessagesHandler(with: self.connection)
    }

    public func start() {
        connection.start()
    }

    public func stop() {
        connection.stop()
    }

    public func send(_ message: Message<ClientCommand>) {
        connection.send(message)
    }

    private func createMessagesHandler(with connection: ClientConnection) -> ClientMessagesHandler {
        let defaultHandler = DefaultClientMessagesHandler(
            connection,
            details: details,
            onClose: { [weak connection] in
                connection?.stop()
            }, onUpdateDetails: { [weak connection, weak self] newDetails in
                connection?.updateDetails(newDetails)
                self?.details = newDetails
                self?.onUpdateDetails?(newDetails)
            }, onClients: { [weak self] clients in
                self?.onUpdateClients?(clients)
            }, onReceivedLetter: { [weak self] letter in
                self?.onReceivedLetter?(letter)
            }, onOutLetterSent: { [weak self] letter in
                self?.onOutLetterSent?(letter)
            }
        )
        return defaultHandler
    }
}
