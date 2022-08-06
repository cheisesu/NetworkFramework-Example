import Foundation
import NetworkCommon

final class DefaultMessagesHandler: ServerMessagesHandler {
    /// Handlers of group of commands that must be handled together
    private var subhandlers: [ServerMessagesHandler] = []
    private var currentGroupHandler: ServerMessagesHandler?
    private weak var dataSender: ServerDataSendable!
    private let connectionId: UUID

    var onClose: () -> Void
    var getClientsMessage: () throws -> Message<ServerCommand>
    var sendMessageToClient: (UUID, Message<ServerCommand>) throws -> Void

    init(connectionId: UUID,
         dataSender: ServerDataSendable,
         subhandlers: [ServerMessagesHandler],
         onClose: @escaping () -> Void,
         getClientsMessage: @escaping () throws -> Message<ServerCommand>,
         sendMessageToClient: @escaping (UUID, Message<ServerCommand>) throws -> Void) {
        self.connectionId = connectionId
        self.dataSender = dataSender
        self.subhandlers = subhandlers
        self.onClose = onClose
        self.getClientsMessage = getClientsMessage
        self.sendMessageToClient = sendMessageToClient

        currentGroupHandler = subhandlers.first(where: { $0.doesCommandStartGroup(.hello) })
    }

    func handle(_ message: Message<ClientCommand>) {
        do {
            switch message.command.visibility {
            case .global: try handleGlobalMessage(message)
            case .onlyGroup: try handleOnlyGroupMessage(message)
            case .regular: try handleRegularCommand(message)
            }
        } catch {
            dataSender.send(.error(error))
        }
    }

    func doesCommandStartGroup(_ command: ClientCommand) -> Bool {
        return false
    }

    func doesCommandEndGroup(_ command: ClientCommand) -> Bool {
        return false
    }

    func doesMessageStartGroup(_ message: Message<ClientCommand>) -> Bool {
        return false
    }

    func doesMessageEndGroup(_ message: Message<ClientCommand>) -> Bool {
        return false
    }

    @available (*, deprecated)
    func add(subhandler: ServerMessagesHandler) {
        subhandlers.append(subhandler)
    }

    private func handleGlobalMessage(_ message: Message<ClientCommand>) throws {
        switch message.command {
        case .close:
            onClose()
        default:
            throw ProtocolError.unexpectedCommand
        }
    }

    private func handleOnlyGroupMessage(_ message: Message<ClientCommand>) throws {
        if let currentGroupHandler = currentGroupHandler {
            currentGroupHandler.handle(message)
            if currentGroupHandler.doesCommandEndGroup(message.command) {
                self.currentGroupHandler = nil
            }
            return
        }
        if let handler = subhandlers.first(where: { $0.doesCommandStartGroup(message.command) }) {
            currentGroupHandler = handler
            handle(message)
            return
        }
    }

    private func handleRegularCommand(_ message: Message<ClientCommand>) throws {
        guard currentGroupHandler == nil else {
            throw ProtocolError.unexpectedCommand
        }

        switch message.command {
        case .clients:
            let message = try getClientsMessage()
            dataSender.send(message)
        case .message:
            var letter: Letter = try message.parsedContent()
            guard letter.senderId == connectionId else {
                throw ProtocolError.incorrectClientId
            }
            letter = Letter(id: UUID(),
                            senderId: letter.senderId,
                            receiverId: letter.receiverId,
                            date: letter.date,
                            text: letter.text)
            let content = try JSONEncoder().encode(letter)
            var message = Message(command: ServerCommand.message, content: content)
            try sendMessageToClient(letter.receiverId, message)
            message = Message(command: .messageSent, content: message.content)
            dataSender.send(message)
        default:
            throw ProtocolError.unexpectedCommand
        }
    }
}
