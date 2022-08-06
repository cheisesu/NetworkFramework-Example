//
//  ClientsState.swift
//  NetworkFramework-Example
//
//  Created by Дмитрий Шелонин on 06.08.2022.
//

import Foundation
import NetworkCommon

struct ClientsState: State, Reduceable {
    var all: [ConnectionDetails] = []
    var activeId: UUID? = nil
    var allHistory: [UUID: [Letter]] = [:]
    var activeHistory: [Letter] = []
    var selfId: UUID? = nil
    
    init() {}

    static func reduce(_ action: Action, _ state: ClientsState) -> ClientsState {
        var state = state
        
        switch action {
        case let AppAction.updateClients(clients):
            state.all = clients
        case let AppAction.selectChat(uuid):
            guard state.activeId != uuid else { break }

            if let newUUID = state.all.first(where: { $0.id == uuid })?.id {
                state.activeId = newUUID
                state.activeHistory = state.allHistory[newUUID] ?? []
            } else {
                state.activeId = nil
                state.activeHistory = []
            }
        case UIAction.becameDisconnected:
            state.all = []
            state.activeId = nil
            state.allHistory = [:]
            state.activeHistory = []
        case let AppAction.incomeLetter(letter):
            guard state.all.contains(where: { $0.id == letter.senderId }) else { break }
            var letters = state.allHistory[letter.senderId] ?? []
            letters.append(letter)
            state.allHistory[letter.senderId] = letters
            if state.activeId != nil {
                state.activeHistory.append(letter)
            }
        case let AppAction.outcomeLetter(letter):
            let letter = letter
            guard state.all.contains(where: { $0.id == letter.receiverId }) else { break }
            var letters = state.allHistory[letter.receiverId] ?? []
            letters.append(letter)
            state.allHistory[letter.receiverId] = letters
            if state.activeId != nil {
                state.activeHistory.append(letter)
            }
        case let AppAction.assignSelfId(id):
            state.selfId = id
        default: break
        }

        return state
    }
}
