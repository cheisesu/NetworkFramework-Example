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
                    let serverPlacement: ToolbarItemPlacement = .navigationBarLeading
                    let otherPlacement: ToolbarItemPlacement = .navigationBarTrailing
#else
                    let serverPlacement: ToolbarItemPlacement = .navigation
                    let otherPlacement: ToolbarItemPlacement = .navigation
#endif
#if os(macOS)
                    ToolbarItem(placement: .navigation) {
                        Button {
                            NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                        } label: {
                            Image(systemName: "sidebar.leading")
                        }
                    }
#endif
                    ToolbarItemGroup(placement: serverPlacement) {
                        if store.state.ui.home.isStartServerButtonVisible {
                            Button {
                                store.dispatch(AppAction.startServer)
                            } label: {
                                Image(systemName: "point.3.connected.trianglepath.dotted")
                            }
                        }
                        if store.state.ui.home.isStopServerButtonVisible {
                            Button {
                                store.dispatch(AppAction.stopServer)
                            } label: {
                                Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                            }
                        }
                    }
                    ToolbarItemGroup(placement: otherPlacement) {
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
                .environmentObject(store)
        }
    }

    private func isConnectViewVisible() -> Binding<Bool> {
        Binding {
            store.state.ui.home.isConnectViewVisible
        } set: { _, _ in
        }
    }
}
