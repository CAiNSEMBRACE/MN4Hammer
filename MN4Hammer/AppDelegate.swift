//
//  AppDelegate.swift
//  MN4Hammer
//
//  Created by LinAn on 2024/12/1.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var appManager: AppManager?

    func applicationDidFinishLaunching(_: Notification) {
        // 初始化崩溃报告
        CrashReporter.setup()
        print("应用已启动并配置了崩溃监控.")

        // 其他初始化逻辑
        appManager = AppManager()
        appManager?.start()
    }

    func applicationWillTerminate(_: Notification) {
        // 应用即将退出，可以在这里添加清理代码

        print("应用即将退出.")
    }
}
