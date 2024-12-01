//
//  BackgroundTaskManager.swift
//  MN4Hammer
//
//  Created by LinAn on 2024/12/1.
//

import Foundation
import AppKit
import AppKit

/// 管理后台任务的类，负责监控目标应用的运行状态
final class BackgroundTaskManager {
    private let accessibilityManager: AccessibilityManager
    private let elementCacheManager: ElementCacheManager
    
    // 目标应用的名称，用于监控的标识
    private let targetAppName: String
    
    // 记录目标应用的运行状态
    private var isTargetAppRunning = false
    
    /// 初始化方法
    /// - Parameter targetAppName: 目标应用的名称
    init(targetAppName: String, accessibilityManager: AccessibilityManager, elementCacheManager: ElementCacheManager) {
        self.accessibilityManager = accessibilityManager
        self.elementCacheManager = elementCacheManager
        self.targetAppName = targetAppName
        setupAppLifecycleMonitoring()
        checkInitialAppStatus()
    }
    
    /// 配置监听器以监控应用生命周期
    private func setupAppLifecycleMonitoring() {
        // 获取工作区的通知中心
        let notificationCenter = NSWorkspace.shared.notificationCenter
        
        // 添加监听器以监控应用启动
        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppLaunch(notification:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        
        // 添加监听器以监控应用终止
        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppTermination(notification:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
    }
    
    /// 检查目标应用是否在监听器启动时已运行
    private func checkInitialAppStatus() {
        // 获取当前所有正在运行的应用
        let runningApps = NSWorkspace.shared.runningApplications
        
        // 检查目标应用是否在其中
        if runningApps.contains(where: { $0.localizedName == targetAppName }) {
            // 更新状态并触发事件处理
            handleAppStatusChange(isRunning: true)
        }
    }
    
    /// 处理应用启动事件
    /// - Parameter notification: 系统发送的通知
    @objc private func handleAppLaunch(notification: Notification) {
        // 获取启动应用的信息
        guard let appInfo = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              appInfo.localizedName == targetAppName else {
            return // 如果不是目标应用，直接返回
        }
        
        // 目标应用已启动，更新状态并触发处理
        handleAppStatusChange(isRunning: true)
    }
    
    /// 处理应用终止事件
    /// - Parameter notification: 系统发送的通知
    @objc private func handleAppTermination(notification: Notification) {
        // 获取终止应用的信息
        guard let appInfo = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              appInfo.localizedName == targetAppName else {
            return // 如果不是目标应用，直接返回
        }
        
        // 目标应用已退出，更新状态并触发处理
        handleAppStatusChange(isRunning: false)
    }
    
    /// 根据运行状态变化触发对应的逻辑
    /// - Parameter isRunning: 目标应用是否运行
    private func handleAppStatusChange(isRunning: Bool) {
        // 避免重复更新
        guard isTargetAppRunning != isRunning else { return }
        
        // 更新运行状态
        isTargetAppRunning = isRunning
        
        // 根据状态调用具体逻辑（需要在这里实现具体业务逻辑）
        if isRunning {
            print("[BackgroundTaskManager] \(targetAppName) 已启动")
            // TODO: 调用 AccessibilityManager 获取元素或初始化任务
            // 这里使用AccessibilityManager获取app元素, 更新Element缓存
            // 这里继续获取窗口元素, 手写工具栏父元素, 手写工具栏button元素, 如果成功则依次更新Element缓存, 否则不更新也不进行后续缓存步骤
        } else {
            print("[BackgroundTaskManager] \(targetAppName) 已退出")
            // TODO: 清理资源或停止任务
            // 清理缓存或执行其他清理操作
            // 这里清理缓存
        }
    }
    
    /// 通过targetAppName尝试获取对应app元素并尝试更新缓存
    private func updateAppCache() -> Bool {
        guard let app = accessibilityManager.getAppElementByName(self.targetAppName), let role = accessibilityManager.getElementRole(app), role == "AXApplication" else {
            return false
        }
        elementCacheManager.addElement(forKey: "AXApplication", element: app)
        return true
    }
    
    /// 尝试更新手写工具栏父元素缓存, 注意这里是更新button缓存之后运行的???
    /// 这里的逻辑比较特殊, 虽然是更新父元素, 但是需要根据button元素得到
    private func updateWriteToolParentCache() -> Bool {
        // 检查app缓存是否还可用
        if !isTargetAppRunning {
            // 加入app已经不再运行,那么直接清空缓存
            clearAllElementCache()
            return false
        }
        
        var window: AXUIElement
        if let app = elementCacheManager.getElement(forKey: "AXApplication"), accessibilityManager.isElementValid(app) {
            // 如果app缓存还能正常使用, 不做处理
        } else {
            // 否则更新缓存
            guard updateAppCache() else {
                return false
            }
        }
        
        
        
        return true
    }
    
    /// 尝试更新手写工具栏
    private func updateWriteToolButtonsCache() -> Bool {
        return false
    }
    
    private func clearAllElementCache() {
        elementCacheManager.clearButtonCache()
        elementCacheManager.clearElementCache()
    }
    
    /// 释放监听器资源
    deinit {
        clearAllElementCache()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}
