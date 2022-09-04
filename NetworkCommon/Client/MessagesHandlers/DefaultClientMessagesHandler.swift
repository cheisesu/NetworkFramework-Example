import Foundation

final class DefaultClientMessagesHandler: ClientMessagesHandler {
    /// Handlers of group of commands that must be handled together
    private var subhandlers: [ClientMessagesHandler] = []
    private var currentGroupHandler: ClientMessagesHandler?
    private weak var dataSender: ClientDataSendable!
    private var details: ConnectionDetails {
        didSet {
            onUpdateDetails(details)
        }
    }

    var onClose: () -> Void
    var onUpdateDetails: (ConnectionDetails) -> Void
    var onClients: ([ConnectionDetails]) -> Void
    var onReceivedLetter: (Letter) -> Void
    var onOutLetterSent: (Letter) -> Void

    init(_ dataSender: ClientDataSendable,
         details: ConnectionDetails,
         onClose: @escaping () -> Void,
         onUpdateDetails: @escaping (ConnectionDetails) -> Void,
         onClients: @escaping ([ConnectionDetails]) -> Void,
         onReceivedLetter: @escaping (Letter) -> Void,
         onOutLetterSent: @escaping (Letter) -> Void) {
        self.dataSender = dataSender
        self.details = details
        self.onClose = onClose
        self.onUpdateDetails = onUpdateDetails
        self.onClients = onClients
        self.onReceivedLetter = onReceivedLetter
        self.onOutLetterSent = onOutLetterSent
    }

    func handle(_ message: Message<ServerCommand>) {
        do {
            switch message.command {
            case .closed: onClose()
            case .hello:
                let id: UUID = try message.parsedContent()
                details = ConnectionDetails(id: id, name: details.name)
                let data = try JSONEncoder().encode(details)
                let message = Message(command: ClientCommand.hello, content: data)
                dataSender.send(message)
            case .clients:
                let clients: [ConnectionDetails] = try message.parsedContent()
                onClients(clients)
            case .error:
                let error: ServerContentError = try message.parsedContent()
                print(error)
            case .tov:
                break
            case .message:
                let letter: Letter = try message.parsedContent()
                onReceivedLetter(letter)
            case .messageSent:
                let letter: Letter = try message.parsedContent()
                onOutLetterSent(letter)
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func doesMessageStartGroup(_ message: Message<ServerCommand>) -> Bool {
        return false
    }

    func doesMessageEndGroup(_ message: Message<ServerCommand>) -> Bool {
        return false
    }

    func add(subhandler: ClientMessagesHandler) {
        subhandlers.append(subhandler)
    }
}
