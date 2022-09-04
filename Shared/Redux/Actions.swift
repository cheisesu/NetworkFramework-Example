//
//  Actions.swift
//  NetworkFramework-Example
//
//  Created by Дмитрий Шелонин on 04.08.2022.
//

import Foundation
import NetworkCommon
import Network

enum AppAction: Action {
    case connectWithAddress(name: String, server: String)
    case connectWithEndpoint(name: String, endpoint: NWEndpoint)
    case updateClients([ConnectionDetails])
    case selectChat(UUID?)
    case sendText(String)
    case incomeLetter(Letter)
    case outcomeLetter(Letter)
    case assignSelfId(UUID)
    case startServer
    case stopServer
}

enum UIAction: Action {
    case dismissConnectView
    case showConnectView
    case disconnect

    case becameConnected
    case becameDisconnected
    case serverBecameStarted
    case serverBecameStopped

    case connectViewUpdateValues(name: String, ip: String)

    case updateEndpoints([NWEndpoint])
}

enum ErrorAction: Action {
    case show(Error)
    case close
}
