import Foundation
import Combine

public final class Store<S: State>: ObservableObject {
    private let reducer: Reducer<S>
    private let middlewares: [Middleware<S>]
    private let operationQueue: OperationQueue
    
    @Published public private(set) var state: S
    
    public init(with reducer: @escaping Reducer<S>, initialState: S, middlewares: [Middleware<S>] = []) {
        self.reducer = reducer
        self.state = initialState
        self.middlewares = middlewares
        
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = 1
        self.operationQueue.qualityOfService = .userInitiated
    }
    
    convenience public init(_ initialState: S, middlewares: [Middleware<S>] = []) where S: Reduceable {
        self.init(with: S.reduce, initialState: initialState, middlewares: middlewares)
    }
    
    public func dispatch(_ action: Action) {
        self.operationQueue.addOperation { [weak self] in
            self?.handle(action)
        }
    }
    
    private func handle(_ action: Action) {
        let dispatch: (Action) -> Void = { [weak self] action in
            self?.dispatch(action)
        }
        
        let state = self.reducer(action, self.state)
        DispatchQueue.main.sync {
            self.state = state
        }
        self.middlewares.forEach {
            $0.handle(action, currentState: { state }, dispatch: dispatch)
        }
    }
}
