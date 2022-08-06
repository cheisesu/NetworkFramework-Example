//
//  LogMiddleware.swift
//  Redux
//
//  Created by Дмитрий Шелонин on 12.09.2021.
//

public final class LogMiddleware<S: State>: Middleware<S> {
    public override init() {
        super.init()
    }
    
    public override func handle(_ action: Action, currentState: @escaping () -> S, dispatch: @escaping (Action) -> Void) {
        print("LogMiddleware: dispatched action \n\t\(action)\nCurrentState: \(currentState())")
    }
}
