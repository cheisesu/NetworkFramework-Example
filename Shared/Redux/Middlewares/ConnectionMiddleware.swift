import Foundation
import NetworkCommon
import Network

final class ConnectionMiddleware: Middleware<AppState> {
    private var client: Client?

    override init() {
        super.init()
    }

    override func handle(_ action: Action, currentState: @escaping () -> AppState, dispatch: @escaping (Action) -> Void) {
        switch action {
        case let AppAction.connectWithAddress(name, server):
            connectIfNeeded(with: name, server: server, dispatch: dispatch)
        case let AppAction.connectWithEndpoint(name, endpoint):
            connectIfNeeded(with: name, endpoint: endpoint, dispatch: dispatch)
        case UIAction.disconnect:
            client?.stop()
        case let AppAction.sendText(text):
            let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            guard let client = client else {
                return
            }
            guard let receiverId = currentState().clients.activeId else {
                return
            }

            do {
                let letter = Letter(senderId: client.id, receiverId: receiverId, date: Date(), text: text)
                let data = try JSONEncoder().encode(letter)
                let message = Message(command: ClientCommand.message, content: data)
                client.send(message)
            } catch {
                dispatch(ErrorAction.show(error))
            }
        default: break
        }
    }

    private func connectIfNeeded(with name: String, server: String, dispatch: @escaping (Action) -> Void) {
        guard client == nil else { return }

        let details = ConnectionDetails(id: UUID(uuid: UUID_NULL), name: name)
        client = Client(server, details: details)

        setupClient(dispatch)

        client?.start()
    }

    private func connectIfNeeded(with name: String, endpoint: NWEndpoint, dispatch: @escaping (Action) -> Void) {
        guard client == nil else { return }

        let details = ConnectionDetails(id: UUID(uuid: UUID_NULL), name: name)
        client = Client(endpoint, details: details)

        setupClient(dispatch)

        client?.start()
    }

    private func setupClient(_ dispatch: @escaping (Action) -> Void) {
        client?.onError = { error in
            dispatch(ErrorAction.show(error))
            dispatch(UIAction.disconnect)
        }
        client?.onClose = { [weak self] in
            dispatch(UIAction.becameDisconnected)
            self?.client = nil
        }
        client?.onCommunicationError = { error in
            dispatch(ErrorAction.show(error))
        }
        client?.onUpdateClients = { clients in
            dispatch(AppAction.updateClients(clients))
        }
        client?.onReceivedLetter = { letter in
            dispatch(AppAction.incomeLetter(letter))
        }
        client?.onOutLetterSent = { letter in
            dispatch(AppAction.outcomeLetter(letter))
        }
        client?.onConnected = {
            dispatch(UIAction.becameConnected)
        }
        client?.onUpdateDetails = { details in
            dispatch(AppAction.assignSelfId(details.id))
        }
    }
}
