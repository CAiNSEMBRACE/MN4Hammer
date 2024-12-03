//
//  RootView.swift
//  MN4Hammer
//
//  Created by LinAn on 2024/11/25.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationSplitView {
            // 侧边栏
            List {
                NavigationLink("Debug", destination: DebugView())
                NavigationLink("信息", destination: InfoView())
            }
            .navigationTitle(Text("菜单"))
        } detail: {
            DebugView()
        }
    }
}
