import Foundation
import Network
import NetworkCommon

final class Client {
    private let connection: ClientConnection
    private let endpoint: NWEndpoint
    private var details: ConnectionDetails

    var id: UUID {
        details.id
    }

    var onError: ((Error) -> Void)? {
        get { connection.onError }
        set { connection.onError = newValue}
    }
    var onClose: (() -> Void)? {
        get { connection.onClose }
        set { connection.onClose = newValue}
    }
    var onCommunicationError: ((Error) -> Void)? {
        get { connection.onCommunicationError }
        set { connection.onCommunicationError = newValue}
    }
    var onConnected: (() -> Void)? {
        get { connection.onConnected }
        set { connection.onConnected = newValue}
    }

    var onUpdateDetails: ((ConnectionDetails) -> Void)?
    var onUpdateClients: (([ConnectionDetails]) -> Void)?
    var onReceivedLetter: ((Letter) -> Void)?
    var onOutLetterSent: ((Letter) -> Void)?

    convenience init(_ address: String, details: ConnectionDetails) {
        let host = NWEndpoint.Host(address)
        let port = NWEndpoint.Port(integerLiteral: defaultPort)
        let endpoint = NWEndpoint.hostPort(host: host, port: port)

        self.init(endpoint, details: details)
    }

    init(_ endpoint: NWEndpoint, details: ConnectionDetails) {
        self.endpoint = endpoint
        self.details = details
        let tcp = NWProtocolTCP.Options()
        let ararat = NWProtocolFramer.Options(definition: .client)
        let params = NWParameters(tls: nil, tcp: tcp)
        params.defaultProtocolStack.applicationProtocols.insert(ararat, at: 0)
        let connection = NWConnection(to: endpoint, using: params)
        self.connection = ClientConnection(connection, details: details)

        self.connection.messagesHandler = createMessagesHandler(with: self.connection)
    }

    func start() {
        connection.start()
    }

    func stop() {
        connection.stop()
    }

    func send(_ message: Message<ClientCommand>) {
        connection.send(message)
    }

    private func createMessagesHandler(with connection: ClientConnection) -> ClientMessagesHandler {
        let defaultHandler = DefaultMessagesHandler(
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
