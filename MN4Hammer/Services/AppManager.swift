//
//  AppManager.swift
//  MN4Hammer
//
//  Created by LinAn on 2024/12/1.
//


class AppManager {
//    let shortcutManager: ShortcutManager
    let accessibilityManager: AccessibilityManager
    let elementCacheManager: ElementCacheManager
    let backgroundTaskManager: BackgroundTaskManager
    let appName: String = "MarginNote 4"

    init() {
        self.accessibilityManager = AccessibilityManager()
        self.elementCacheManager = ElementCacheManager()
        self.backgroundTaskManager = BackgroundTaskManager(
            targetAppName: appName,
            accessibilityManager: accessibilityManager,
            elementCacheManager: elementCacheManager
        )
//        self.shortcutManager = ShortcutManager(appManager: self)
    }

    func start() {
        // 启动各管理器
//        shortcutManager.startListening()
    }

}
