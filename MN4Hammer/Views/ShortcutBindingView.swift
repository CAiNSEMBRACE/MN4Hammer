//
//  ShortcutBindingView.swift
//  MN4Hammer
//
//  Created by LinAn on 2024/12/2.
//

import SwiftUI

struct ShortcutBindingView: View {
    @ObservedObject var shortcutManager: ShortcutManager
    @State private var isBindingShortcut = false
    @State private var currentShortcut: String = ""
    @State private var conflictMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("快捷键管理")
                .font(.largeTitle)
                .bold()

            // 已绑定快捷键列表
            List {
                ForEach(shortcutManager.shortcuts, id: \.id) { shortcut in
                    HStack {
                        Text(shortcut.description)
                        Spacer()
                        Text(shortcut.keyCombination)
                            .foregroundColor(.secondary)
                        Button(action: {
                            shortcutManager.removeShortcut(shortcut)
                        }) {
                            Text("删除")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }

            // 新增快捷键区域
            if isBindingShortcut {
                VStack {
                    Text("请按下快捷键")
                        .font(.headline)

                    Text(currentShortcut.isEmpty ? "等待输入..." : currentShortcut)
                        .foregroundColor(.blue)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )

                    if let conflictMessage = conflictMessage {
                        Text(conflictMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    HStack {
                        Button("确认") {
                            if let error = shortcutManager.addShortcut(currentShortcut) {
                                conflictMessage = error.localizedDescription
                            } else {
                                conflictMessage = nil
                                isBindingShortcut = false
                                currentShortcut = ""
                            }
                        }
                        .disabled(currentShortcut.isEmpty)

                        Button("取消") {
                            isBindingShortcut = false
                            currentShortcut = ""
                            conflictMessage = nil
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            } else {
                Button("新增快捷键") {
                    isBindingShortcut = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .onReceive(shortcutManager.shortcutInputPublisher) { input in
            currentShortcut = input
        }
    }
}
