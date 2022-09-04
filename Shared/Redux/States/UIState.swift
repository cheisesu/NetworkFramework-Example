//
//  UIState.swift
//  NetworkFramework-Example
//
//  Created by Дмитрий Шелонин on 04.08.2022.
//

import Foundation

struct UIState: State, Reduceable {
    var error: Error = .init()
    var home: Home = .init()
    var connectView: ConnectView = .init()
    
    init() {}

    static func reduce(_ action: Action, _ state: UIState) -> UIState {
        var state = state

        state.error = .reduce(action, state.error)
        state.home = .reduce(action, state.home)
        state.connectView = .reduce(action, state.connectView)

        return state
    }
}

extension UIState {
    struct Error: State, Reduceable {
        var errors: [Swift.Error] = []
        var errorText: String = ""
        var isErrorShown: Bool = false

        init() {}

        static func reduce(_ action: Action, _ state: UIState.Error) -> UIState.Error {
            var state = state

            switch action {
            case let ErrorAction.show(error):
                state.isErrorShown = true
                state.errors.append(error)
                state.errorText = state.errors.map { $0.localizedDescription }.joined(separator: "\n")
            case ErrorAction.close:
                state.errors.removeAll()
                state.errorText = ""
                state.isErrorShown = false
            default: break
            }

            return state
        }
    }

    struct Home: State, Reduceable {
        var isConnectViewVisible: Bool = false
        var isConnectButtonVisible: Bool = true
        var isDisconnectButtonVisible: Bool = false
        var isStartServerButtonVisible: Bool = true
        var isStopServerButtonVisible: Bool = false

        init() {}

        static func reduce(_ action: Action, _ state: UIState.Home) -> UIState.Home {
            var state = state

            switch action {
            case UIAction.dismissConnectView: state.isConnectViewVisible = false
            case UIAction.showConnectView: state.isConnectViewVisible = true
            case UIAction.becameConnected:
                state.isConnectButtonVisible = false
                state.isDisconnectButtonVisible = true
            case UIAction.becameDisconnected:
                state.isConnectButtonVisible = true
                state.isDisconnectButtonVisible = false
            case UIAction.serverBecameStarted:
                state.isStartServerButtonVisible = false
                state.isStopServerButtonVisible = true
            case UIAction.serverBecameStopped:
                state.isStartServerButtonVisible = true
                state.isStopServerButtonVisible = false
            default: break
            }

            return state
        }
    }

    struct ConnectView: State, Reduceable {
        var isConnectButtonEnabled: Bool = false

        init() {}

        static func reduce(_ action: Action, _ state: UIState.ConnectView) -> UIState.ConnectView {
            var state = state

            switch action {
            case let UIAction.connectViewUpdateValues(name, ip):
                state.isConnectButtonEnabled = !name.isEmpty && !ip.isEmpty
            default: break
            }

            return state
        }
    }
}
