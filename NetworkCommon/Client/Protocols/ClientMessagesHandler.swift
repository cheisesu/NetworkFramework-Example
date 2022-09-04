import Foundation

public protocol ClientMessagesHandler {
    func handle(_ message: Message<ServerCommand>)
    func doesMessageStartGroup(_ message: Message<ServerCommand>) -> Bool
    func doesMessageEndGroup(_ message: Message<ServerCommand>) -> Bool
}
