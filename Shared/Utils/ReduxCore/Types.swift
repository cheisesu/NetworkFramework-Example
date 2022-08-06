public protocol State {
    init()
}

public protocol Action {}

public typealias Reducer<S: State> = (_ action: Action, _ state: S) -> S

public protocol Reduceable: State {
    static func reduce(_ action: Action, _ state: Self) -> Self
}

open class Middleware<S: State> {
    public typealias Handler = (Action, @escaping () -> S, @escaping (Action) -> Void) -> Void
    
    private let handler: Handler?
    
    public init() {
        self.handler = nil
    }
    
    public init(with handler: @escaping Handler) {
        self.handler = handler
    }
    
    open func handle(_ action: Action,
                     currentState: @escaping () -> S,
                     dispatch: @escaping (Action) -> Void) {
        handler?(action, currentState, dispatch)
    }
}

public enum AsyncAction<V, F: Error>: Action {
    case empty
    case start
    case loading
    case cancel
    case progress(UInt)
    case success(V)
    case failure(F)
}

public enum AsyncState<V, E: Error>: State, Reduceable {
    case none
    case loading
    case success(V)
    case failure(E)
    
    public init() {
        self = .none
    }
    
    public static func reduce(_ action: Action, _ state: AsyncState<V, E>) -> AsyncState<V, E> {
        var state = state
        switch action {
        case AsyncAction<V, E>.empty: state = .none
        case AsyncAction<V, E>.cancel: state = .none
        case AsyncAction<V, E>.start: break
        case AsyncAction<V, E>.loading: state = .loading
        case AsyncAction<V, E>.progress: state = .loading
        case AsyncAction<V, E>.success(let value): state = .success(value)
        case AsyncAction<V, E>.failure(let error): state = .failure(error)
        default: break
        }
        return state
    }
}

extension AsyncState: Codable {
    public init(from decoder: Decoder) throws {
        self = .none
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("none")
    }
}
