//
//  InfoView.swift
//  MN4Hammer
//
//  Created by LinAn on 2024/11/25.
//

import SwiftUI

struct InfoView: View {
    var body: some View {
        VStack {
            Image(systemName: "hammer.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("这是一个快速切换MarginNote4笔刷的工具.\n始于AppleScript脚本, 现用swift语言重写\n通过Accessibility API实现跨应用控制.")
        }
        .padding()
        .navigationTitle(Text("信息"))
    }
}
