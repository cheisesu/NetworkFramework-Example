//
//  ConnectView.swift
//  NetworkCommon
//
//  Created by Дмитрий Шелонин on 04.08.2022.
//

import SwiftUI
import Network

struct ConnectView: View {
    @EnvironmentObject private var store: Store<AppState>

    @SwiftUI.State private var name: String = "User \(Int.random(in: 0..<10))"
    @SwiftUI.State private var server: String = "192.168.10.119"

    var body: some View {
        VStack(alignment: .leading) {
            Text("Your name:")
                .font(.title)
            TextField("your name", text: nameBind())
            Divider()
            Text("Server ip:")
                .font(.title)
            TextField("0.0.0.0", text: serverBind())
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif
            Button("Connect") {
                store.dispatch(UIAction.dismissConnectView)
                store.dispatch(AppAction.connectWithAddress(name: name, server: server))
            }
            .disabled(!store.state.ui.connectView.isConnectButtonEnabled)

            EndpointsView(endpoints: store.state.endpoints) { endpoint in
                store.dispatch(UIAction.dismissConnectView)
                store.dispatch(AppAction.connectWithEndpoint(name: name, endpoint: endpoint))
            }
        }
#if os(macOS)
        .frame(width: 320, height: 320, alignment: .top)
#elseif os(iOS)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
#endif
        .padding()
        .interactiveDismissDisabled()
        .onAppear {
            store.dispatch(UIAction.connectViewUpdateValues(name: name, ip: server))
        }
    }

    private func nameBind() -> Binding<String> {
        Binding {
            name
        } set: { value in
            name = value
            store.dispatch(UIAction.connectViewUpdateValues(name: name, ip: server))
        }
    }

    private func serverBind() -> Binding<String> {
        Binding {
            server
        } set: { value in
            server = value
            store.dispatch(UIAction.connectViewUpdateValues(name: name, ip: server))
        }
    }
}

struct EndpointsView: View {
    let endpoints: [NWEndpoint]
    let onSelect: (NWEndpoint) -> Void

    var body: some View {
        if !endpoints.isEmpty {
            Divider()
            Text("Or connect via:")
        }
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<endpoints.count, id: \.self) { index in
                    let endpoint = endpoints[index]
                    Button {
                        onSelect(endpoint)
                    } label: {
                        HStack {
                            Text(endpoint.debugDescription)
                                .padding(8)
                            Spacer(minLength: 0)
                        }
                        .background(Color.mint.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    Divider()
                }
            }
        }
    }
}
