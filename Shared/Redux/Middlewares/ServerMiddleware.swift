import Foundation
import NetworkCommon

final class ServerMiddleware: Middleware<AppState> {
    private var server: Server!

    override func handle(_ action: Action, currentState: @escaping () -> AppState, dispatch: @escaping (Action) -> Void) {
        switch action {
        case AppAction.startServer:
            startServerIfNeeded(dispatch)
        case AppAction.stopServer:
            server?.stop()
        case UIAction.serverBecameStopped:
            server = nil
        default: break
        }
    }

    private func startServerIfNeeded(_ dispatch: @escaping (Action) -> Void) {
        guard server == nil else { return }
        do {
            server = try Server(8888)
            server.onError = { error in
                dispatch(ErrorAction.show(error))
            }
            server.onStart = {
                dispatch(UIAction.serverBecameStarted)
            }
            server.onStop = {
                dispatch(UIAction.serverBecameStopped)
            }
            server.start()
        } catch {
            dispatch(ErrorAction.show(error))
        }
    }
}
