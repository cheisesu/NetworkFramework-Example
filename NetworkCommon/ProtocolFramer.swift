import Foundation
import Network

extension NWProtocolFramer.Definition {
    public static let client = NWProtocolFramer.Definition(implementation: ProtocolFramer<ServerCommand, ClientCommand>.self)
    public static let server = NWProtocolFramer.Definition(implementation: ProtocolFramer<ClientCommand, ServerCommand>.self)
}

extension ProtocolFramer where Input == ServerCommand, Output == ClientCommand {
    static var definition: NWProtocolFramer.Definition { return .client }
}

public class ProtocolFramer<Input, Output>: NWProtocolFramerImplementation
where
Input: Codable & RawRepresentable,
Output: Codable & RawRepresentable,
Input.RawValue == String,
Output.RawValue == String {
    public static var label: String {
        "ProtocolFramer<\(Input.self), \(Output.self)>"
    }
    private class var definition: NWProtocolFramer.Definition {
        if Input.self is ServerCommand.Type, Output.self is ClientCommand.Type {
            return .client
        } else if Input.self is ClientCommand.Type, Output.self is ServerCommand.Type {
            return .server
        }
        return .init(implementation: Self.self)
    }

    required public init(framer: NWProtocolFramer.Instance) {
    }

    public func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult {
        return .ready
    }

    public func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        var minIncomleteLen: Int = 1
        while true {
            var messageData: Data?
            let didParse = framer.parseInput(minimumIncompleteLength: minIncomleteLen,
                                             maximumLength: .max) { buffer, isComplete in
                guard let buffer = buffer else {
                    return 0
                }
                let data = Data(buffer)
                if let range = data.range(of: .end) {
                    let rawMessageData = Data(data[0..<range.endIndex])
                    messageData = rawMessageData
                    let leftData = Data(data[range.endIndex...])
                    minIncomleteLen = leftData.count + 1
                } else {
                    minIncomleteLen = buffer.count + 1
                }
                return 0
            }

            guard didParse else { return 0 }
            guard let data = messageData else { continue}

            let metadata = NWProtocolFramer.Message(definition: Self.definition)
            do {
                let message = try Message<Input>(data)
                metadata["message"] = message
            } catch {
                metadata["error"] = error
            }

            guard framer.deliverInputNoCopy(length: data.count, message: metadata, isComplete: false) else {
                return 0
            }
            messageData = nil
        }
    }

    public func handleOutput(framer: NWProtocolFramer.Instance, message: NWProtocolFramer.Message, messageLength: Int, isComplete: Bool) {
        guard let message = message["message"] as? Message<Output> else {
            assertionFailure("Unknown message type")
            return
        }
        let data = message.data
        framer.writeOutput(data: data)
    }

    public func wakeup(framer: NWProtocolFramer.Instance) {
    }

    public func stop(framer: NWProtocolFramer.Instance) -> Bool {
        return true
    }

    public func cleanup(framer: NWProtocolFramer.Instance) {
    }
}
