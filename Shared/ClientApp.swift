//
//  ClientApp.swift
//  Shared
//
//  Created by Дмитрий Шелонин on 03.08.2022.
//

import SwiftUI

@main
struct ClientApp: App {
    @StateObject var store = Store(AppState(), middlewares: [
        LogMiddleware(),
        ConnectionMiddleware(),
        ServersBrowserMiddleware()
    ])
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .alert("Error occured", isPresented: isErrorShown()) {
                    Button("OK") {
                        store.dispatch(ErrorAction.close)
                    }
                } message: {
                    Text(store.state.ui.error.errorText)
                }
        }
        .commands {
            SidebarCommands()
        }
    }
    
    private func isErrorShown() -> Binding<Bool> {
        Binding {
            store.state.ui.error.isErrorShown
        } set: { _ in
        }
    }
}
