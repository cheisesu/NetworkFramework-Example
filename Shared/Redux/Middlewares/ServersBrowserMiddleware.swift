//
//  ServersBrowserMiddleware.swift
//  NetworkFramework-Example
//
//  Created by Дмитрий Шелонин on 06.08.2022.
//

import Foundation
import NetworkCommon
import Network

final private class LocalNetworkServers {
    private let browser: NWBrowser
    private let queue: DispatchQueue

    var onFoundEntpoints: (([NWEndpoint]) -> Void)?

    init() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        browser = NWBrowser(for: .bonjour(type: "_network_server._tcp", domain: nil), using: parameters)
        queue = DispatchQueue(label: "com.servers_browser")
    }

    func start() {
        browser.stateUpdateHandler = { newState in
            print("BROWSER: new state \(newState)")
        }
        browser.browseResultsChangedHandler = { [weak self] results, changes in
            var endpoints: [NWEndpoint] = []
            for result in results {
                if case NWEndpoint.service = result.endpoint {
                    endpoints.append(result.endpoint)
                }
            }
            self?.onFoundEntpoints?(endpoints)
        }
        browser.start(queue: queue)
    }

    func stop() {
        browser.cancel()
    }
}

final class ServersBrowserMiddleware: Middleware<AppState> {
    private let browser = LocalNetworkServers()

    override func handle(_ action: Action, currentState: @escaping () -> AppState, dispatch: @escaping (Action) -> Void) {
        switch action {
        case UIAction.showConnectView:
            browser.onFoundEntpoints = { endpoints in
                dispatch(UIAction.updateEndpoints(endpoints))
            }
            browser.start()
        case UIAction.dismissConnectView:
            browser.stop()
        default: break
        }
    }
}
