//
//  ChatView.swift
//  NetworkFramework-Example
//
//  Created by Дмитрий Шелонин on 06.08.2022.
//

import SwiftUI
import NetworkCommon

struct ChatView: View {
    @EnvironmentObject private var store: Store<AppState>
    @SwiftUI.State private var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { proxy in
                ScrollView {
                    ScrollViewReader { reader in
                        LazyVStack(spacing: 0) {
                            ForEach(store.state.clients.activeHistory) { letter in
                                let position: BubblePosition = letter.senderId == store.state.clients.selfId ? .right : .left
                                let color: Color = letter.senderId == store.state.clients.selfId ? .mint : .indigo
                                ChatBubbleView(position: position, color: color.opacity(0.7), containerWidth: proxy.size.width - 8 - 8) {
                                    ChatContentView(letter: letter)
                                }
                                .id(letter.id)
                            }
                            .onChange(of: store.state.clients.activeHistory) { _ in
                                reader.scrollTo(store.state.clients.activeHistory.last?.id, anchor: .bottom)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height - 8 - 8, alignment: .bottom)
                        .padding(8)
                    }
                }
            }
            Divider()
            HStack {
                TextEditor(text: $text)
                    .frame(maxHeight: 42)
                    .padding(.vertical, 4)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.gray, lineWidth: 1))
                Button {
                    store.dispatch(AppAction.sendText(text))
                    text = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(Color.blue)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: [.command])
            }
            .padding(.horizontal, nil)
            .padding(.vertical, 8)
        }
    }
}

enum BubblePosition {
    case left
    case right
}

struct ChatBubbleView<Content: View>: View {
    let position: BubblePosition
    let color: Color
    let containerWidth: CGFloat
    let content: () -> Content

    init(position: BubblePosition, color: Color, containerWidth: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.containerWidth = containerWidth
        self.color = color
        self.position = position
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if position == .right {
                Spacer(minLength: 0.2 * containerWidth)
            }
            content()
                .padding(8)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            if position == .left {
                Spacer(minLength: 0.2 * containerWidth)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct ChatContentView: View {
    let letter: Letter

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(letter.text)
                .lineLimit(nil)
                .font(.body)
                .foregroundColor(.primary)

            Text(letter.formattedDate)
                .multilineTextAlignment(.trailing)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
