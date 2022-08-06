import Foundation

public protocol ServerMessagesHandler {
    func handle(_ message: Message<ClientCommand>)
    func doesCommandStartGroup(_ command: ClientCommand) -> Bool
    func doesCommandEndGroup(_ command: ClientCommand) -> Bool
    
    @available (*, deprecated, message: "Use `doesCommandStartGroup` instead")
    func doesMessageStartGroup(_ message: Message<ClientCommand>) -> Bool
    @available (*, deprecated, message: "Use `doesCommandEndGroup` instead")
    func doesMessageEndGroup(_ message: Message<ClientCommand>) -> Bool
}
