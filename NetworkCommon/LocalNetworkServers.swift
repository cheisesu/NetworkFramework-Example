import Foundation
import Network

public final class LocalNetworkServers {
    private let browser: NWBrowser
    private let queue: DispatchQueue

    public var onFoundEntpoints: (([NWEndpoint]) -> Void)?

    public init() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        browser = NWBrowser(for: .bonjour(type: "_network_server._tcp", domain: nil), using: parameters)
        queue = DispatchQueue(label: "com.servers_browser")
    }

    public func start() {
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

    public func stop() {
        browser.cancel()
    }
}
