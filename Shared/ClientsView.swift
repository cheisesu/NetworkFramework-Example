import SwiftUI
import NetworkCommon

struct ClientsView: View {
    @EnvironmentObject private var store: Store<AppState>

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(store.state.clients.all) { client in
                    NavigationLink(tag: client.id, selection: itemSelection()) {
                        ChatView()
                    } label: {
                        ClientItemView(details: client)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        
    }

    private func itemSelection() -> Binding<UUID?> {
        Binding {
            store.state.clients.activeId
        } set: { value in
            store.dispatch(AppAction.selectChat(value))
        }
    }
}

private struct ClientItemView: View {
    let details: ConnectionDetails

    var body: some View {
        HStack(alignment: .center) {
            Text(details.name)
            Spacer()
            Image(systemName: "chevron.right")
        }
        .padding()
        .background(Color.mint.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.vertical, 4)
        .padding(.horizontal, nil)
    }
}
