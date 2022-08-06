import Foundation

public struct Message<Command: Codable & RawRepresentable>: Codable
where Command.RawValue == String {
    public let command: Command
    public let content: Data?

    public init(command: Command, content: Data?) {
        self.command = command
        self.content = content
    }
}

extension Message {
    public init(_ data: Data) throws {
        var data = data
        if data.hasSuffix(.end) {
            data.removeLast(Data.end.count)
        }
        let splitIndex: Data.Index
        let contentIndex: Data.Index
        if let range = data.firstRange(of: Data(" ".utf8)) {
            splitIndex = range.startIndex
            contentIndex = range.endIndex
        } else {
            splitIndex = data.endIndex
            contentIndex = data.endIndex
        }
        let commandData = data[0..<splitIndex]
        guard
            let cmdStr = String(data: commandData, encoding: .utf8),
            let cmd = Command(rawValue: cmdStr)
        else {
            throw ProtocolError.unknownCommand
        }
        command = cmd
        let content = data[contentIndex...]
        if content.isEmpty {
            self.content = nil
        } else {
            self.content = content
        }
    }
    
    /// Creates message data
    public var data: Data {
        let commandData = Data(command.rawValue.utf8)
        var result = Data()
        result.append(commandData)
        if let content = content {
            result.append(contentsOf: " ".utf8)
            result.append(content)
        }
        result.append(.end)

        return result
    }

    public func parsedContent<T: Decodable>() throws -> T {
        guard let content = content else {
            throw ProtocolError.noContent
        }
        do {
            let decoder = JSONDecoder()
            let content = try decoder.decode(T.self, from: content)
            return content
        } catch {
            throw ProtocolError.wrongContent(error)
        }
    }
}

extension Message where Command == ServerCommand {
    public static func error(_ error: Error) -> Message<ServerCommand> {
        var contentData: Data?
        do {
            let content = ServerContentError(error)
            contentData = try JSONEncoder().encode(content)
        } catch {
            assertionFailure(error.localizedDescription)
        }
        return Message(command: .error, content: contentData)
    }
}
