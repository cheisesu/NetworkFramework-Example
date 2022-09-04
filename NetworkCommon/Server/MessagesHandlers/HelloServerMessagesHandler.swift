import Foundation

final class HelloServerMessagesHandler: ServerMessagesHandler {
    private weak var dataSender: ServerDataSendable!
    private let connectionId: UUID
    private var finished: Bool = false
    private let onClientDetails: (ConnectionDetails) -> Void
    private let onFinish: () -> Void

    init(connectionId: UUID,
         dataSender: ServerDataSendable,
         onClientDetails: @escaping (ConnectionDetails) -> Void,
         onFinish: @escaping () -> Void) {
        self.connectionId = connectionId
        self.dataSender = dataSender
        self.onClientDetails = onClientDetails
        self.onFinish = onFinish
    }

    func handle(_ message: Message<ClientCommand>) {
        do {
            switch message.command {
            case .hello:
                let content: ConnectionDetails = try message.parsedContent()
                guard content.id == connectionId else {
                    throw ProtocolError.incorrectClientId
                }
                onClientDetails(content)
                dataSender.send(Message(command: .tov, content: nil))
                finished = true
                onFinish()
            default:
                throw ProtocolError.unexpectedCommand
            }
        } catch {
            dataSender.send(.error(error))
        }
    }

    func doesCommandStartGroup(_ command: ClientCommand) -> Bool {
        return command == .hello && !finished
    }

    func doesCommandEndGroup(_ command: ClientCommand) -> Bool {
        return command == .hello
    }

    func doesMessageStartGroup(_ message: Message<ClientCommand>) -> Bool {
        return message.command == .hello && !finished
    }

    func doesMessageEndGroup(_ message: Message<ClientCommand>) -> Bool {
        return message.command == .hello
    }
}
