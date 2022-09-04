import Foundation

public protocol ServerMessagesHandler {
    func handle(_ message: Message<ClientCommand>)
    func doesCommandStartGroup(_ command: ClientCommand) -> Bool
    func doesCommandEndGroup(_ command: ClientCommand) -> Bool
}
