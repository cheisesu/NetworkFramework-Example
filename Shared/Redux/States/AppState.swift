//
//  AppState.swift
//  NetworkFramework-Example
//
//  Created by Дмитрий Шелонин on 04.08.2022.
//

import Foundation
import Network

struct AppState: State, Reduceable {
    var ui: UIState = .init()
    var clients: ClientsState = .init()
    var endpoints: [NWEndpoint] = []
    
    init() {}

    static func reduce(_ action: Action, _ state: AppState) -> AppState {
        var state = state

        state.ui = .reduce(action, state.ui)
        state.clients = .reduce(action, state.clients)

        switch action {
        case let UIAction.updateEndpoints(endpoints):
            state.endpoints = endpoints
        default: break
        }

        return state
    }
}
