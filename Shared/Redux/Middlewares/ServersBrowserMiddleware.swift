import Foundation
import NetworkCommon
import Network

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
