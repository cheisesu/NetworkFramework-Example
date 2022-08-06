//
//  ContentView.swift
//  Shared
//
//  Created by Дмитрий Шелонин on 03.08.2022.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: Store<AppState>

    var body: some View {
        NavigationView {
            ClientsView()
                .navigationTitle("Client example")
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .toolbar {
#if os(iOS)
                    let placement: ToolbarItemPlacement = .navigationBarTrailing
#else
                    let placement: ToolbarItemPlacement = .navigation
#endif
                    ToolbarItemGroup(placement: placement) {
#if os(macOS)
                        Button {
                            NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                        } label: {
                            Image(systemName: "sidebar.leading")
                        }
#endif
                        if store.state.ui.home.isConnectButtonVisible {
                            Button {
                                store.dispatch(UIAction.showConnectView)
                            } label: {
                                Image(systemName: "personalhotspot.circle")
                            }
                        }
                        if store.state.ui.home.isDisconnectButtonVisible {
                            Button {
                                store.dispatch(UIAction.disconnect)
                            } label: {
                                Image(systemName: "personalhotspot.circle.fill")
                            }
                        }
                    }
                }
        }
#if os(iOS)
        .navigationViewStyle(.stack)
#endif
        .sheet(isPresented: isConnectViewVisible()) {
            ConnectView()
        }
    }

    private func isConnectViewVisible() -> Binding<Bool> {
        Binding {
            store.state.ui.home.isConnectViewVisible
        } set: { _, _ in
        }
    }
}
