//
//  BackgroundTaskManager.swift
//  MN4Hammer
//
//  Created by LinAn on 2024/12/1.
//

import AppKit
import Foundation

/// 管理后台任务的类，负责监控目标应用的运行状态
final class BackgroundTaskManager {
    private let accessibilityManager: AccessibilityManager
    private let elementCacheManager: ElementCacheManager
    private let targetAppName: String // 目标应用的名称，用于监控的标识
    private var isTargetAppRunning = false // 记录目标应用的运行状态
    private var retryTimer: Timer? // 定时器对象
    private let retryInterval: TimeInterval = 5.0 // 默认重试间隔时间
    private var maxRetryAttempts = 3 // 最大重试次数
    private var currentRetryAttempt = 0 // 当前重试次数
    private var isUpdating = false // 是否正在执行更新操作

    // 按钮元素size数据, 用于筛选
    private var buttonWidth: CGFloat = 40 // 按钮宽度限制
    private var buttonHeigh: CGFloat = 40 // 按钮高度限制
    private var toleranceRange: CGFloat = 0.01 // 可接受的误差范围

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
              appInfo.localizedName == targetAppName
        else {
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
              appInfo.localizedName == targetAppName
        else {
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

            // MARK: 后台业务入口

            updateCache()

        } else {
            print("[BackgroundTaskManager] \(targetAppName) 已退出")
            // TODO: 清理资源或停止任务
            // 清理缓存
            clearAllElementCache()
        }
    }

    // MARK: 缓存更新总入口

    private func updateCache(triggeredByUser: Bool = false) {
        guard !isUpdating else {
            print("[BackgroundTaskManager] 更新操作已在进行中，跳过本次更新")
            return
        }

        isUpdating = true // 标记更新开始

        // 如果是用户触发更新，停止定时器（避免冲突）
        if triggeredByUser {
            stopRetryTimer()
        }

        // 缓存更新逻辑
        let updateSuccess = attemptToUpdateCache()

        if updateSuccess {
            print("[BackgroundTaskManager] 缓存更新成功")
            stopRetryTimer() // 成功时停止重试
            currentRetryAttempt = 0 // 重置重试计数
        } else {
            print("[BackgroundTaskManager] 缓存更新失败")
            if triggeredByUser {
                print("[BackgroundTaskManager] 用户触发更新失败，不启动定时重试")
            } else {
                scheduleRetry() // 非用户触发的失败启动重试逻辑
            }
        }

        isUpdating = false // 标记更新结束
    }

    /// 更新缓存的逻辑
    /// - Returns: 是否更新成功
    private func attemptToUpdateCache() -> Bool {
        // TODO: 依次获取app,window,buttons
        var app: AXUIElement?
        var window: AXUIElement?

        // ------------检查app更新------------
        if let appCache = elementCacheManager.getApp(), accessibilityManager.isElementValid(appCache) {
            app = appCache
            print("app缓存已存在且有效")
        } else {
            guard let appElement = accessibilityManager.getAppElementByName(targetAppName) else {
                print("attemptToUpdateCache(): 无法获取app")
                return false
            }
            elementCacheManager.addApp(appElement)
            app = appElement
            print("app缓存完成")
        }

        // ------------检查window更新------------
        if let windowCache = elementCacheManager.getMainWindow(), accessibilityManager.isElementValid(windowCache), accessibilityManager.isElementFocused(windowCache) {
            // 如果缓存已存在,且有效,且被聚焦,则说明缓存不需要更新
            print("window缓存已存在且有效")
            window = windowCache
        } else {
            guard let windowElement = accessibilityManager.getFocusedWindow(from: app!) else {
                // 这里如果无法获取window,说明程序没有开启窗口, 直接退出
                print("无法获取窗口")
                return false
            }
            elementCacheManager.addWindow(windowElement)
            window = windowElement
            print("window缓存更新完成")
        }

        // ------------检查button更新------------
        if isButtonCacheValid() {
            print("button缓存验证成功")
            return true
        }

        // 清除button缓存
        elementCacheManager.clearButtonCache()

        // 通过window检索button
        // AXWindow->AXGroup->AXGroup->AXButton
        guard let layer2Elements: [AXUIElement] = accessibilityManager.getElementChildren(in: window!) else {
            print("窗口为空, 请检查获取的AXWindow是否出错.")
            return false
        }
        // 检索第二层中的AXGroup
        var layer2AXGroups: [AXUIElement] = [] // 假设存在多个
        for layer2Element in layer2Elements {
            // 根据解包结果获取role
            if let role = accessibilityManager.getElementRole(layer2Element), role == "AXGroup" {
                // if-String
                layer2AXGroups.append(layer2Element)
            }
        }

        // 这里只选取layer2第一个AXGroup
        guard layer2AXGroups.count > 0 else {
            print("layer2中无AXGroup, 请检查父元素windowElement是否正确.")
            return false
        }
        let layer2AXGroup: AXUIElement = layer2AXGroups[0]

        // 获取第三层的元素
        guard let layer3Elements: [AXUIElement] = accessibilityManager.getElementChildren(in: layer2AXGroup) else {
            print("第三层无数据, 检查传入的父元素是否错位.")
            return false
        }

        // 检索第三层的AXGroup
        var layer3AXGroups: [AXUIElement] = [] // 假设有多个
        for layer3Element in layer3Elements {
            // 解包获取role用于判断
            if let role = accessibilityManager.getElementRole(layer3Element), role == "AXGroup" {
                layer3AXGroups.append(layer3Element)
            }
        }

        // 检查是否成功检索到AXGroup, 这里只选择第三层第一个AXGroup
        guard layer3AXGroups.count > 0 else {
            print("layer3中无AXGroup, 请检查父元素layer3Elements是否正确. gpowtb04")
            return false
        }

        // 得到writeToolButtons的父元素-位于第三层的AXGroup
        let layer3AXGroup: AXUIElement = layer3AXGroups[0]

        // 这里开始检索button按钮

        // MARK: Button检索逻辑

        var buttonNumber = 0 // 用于给button计数
        guard let children = accessibilityManager.getElementChildren(in: layer3AXGroup), children.count > 0 else {
            print("无法检索到button层级, 检查app窗口是否开启")
            return false
        }

        for child in children {
            guard let role = accessibilityManager.getElementRole(child), role == "AXButton", isTrueButton(child) else {
                continue
            }
            elementCacheManager.addButton(child)
            buttonNumber += 1
        }

        if buttonNumber == 0 {
            print("未找到button, 传入元素或筛选条件")
            return false
        }
        print("button更新完毕")
        return true
    }

    private func isTrueButton(_ button: AXUIElement) -> Bool {
        // MARK: button筛选数据

        // 目前的筛选方案是使用size限制, 存在问题是无法分辨是否是插件的按钮
        guard let size = accessibilityManager.getElementSize(for: button) else {
            print("[isTrueButton]无法获取元素size数据,检查其是否可见")
            return false
        }

        return abs(size.width - buttonWidth) < toleranceRange && abs(size.height - buttonHeigh) < toleranceRange
    }

    /// 设置重试定时器
    private func scheduleRetry() {
        guard currentRetryAttempt < maxRetryAttempts else {
            print("[BackgroundTaskManager] 达到最大重试次数，停止重试")
            stopRetryTimer()
            return
        }

        retryTimer = Timer.scheduledTimer(withTimeInterval: retryInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.currentRetryAttempt += 1
            print("[BackgroundTaskManager] 第 \(self.currentRetryAttempt) 次重试")
            self.updateCache() // 再次调用更新缓存逻辑
        }
    }

    /// 停止重试定时器
    private func stopRetryTimer() {
        retryTimer?.invalidate()
        retryTimer = nil
    }

    /// 用户触发操作时检查缓存可用性
    func handleUserAction() {
        print("[BackgroundTaskManager] 用户操作触发缓存检查")
        if isButtonCacheValid() {
            print("[BackgroundTaskManager] 缓存可用，执行用户操作")
        } else {
            print("[BackgroundTaskManager] 缓存不可用，触发更新")
            updateCache(triggeredByUser: true)
        }
    }

    /// 检查缓存是否有效
    private func isButtonCacheValid() -> Bool {
        // 这里需要一个特殊的检查:
        // 假如当前的缓存的window(单窗口模式)未被聚焦,即时button可用也需要更新
        guard let window = elementCacheManager.getMainWindow(), accessibilityManager.isElementValid(window), accessibilityManager.isElementFocused(window) else {
            return false
        }

        guard let buttons = elementCacheManager.getAllButtons() else {
            return false
        }
        for button in buttons {
            if !accessibilityManager.isElementValid(button) {
                return false
            }
        }
        return true
    }

    /// 通过targetAppName尝试获取对应app元素并尝试更新缓存
    private func updateAppCache() -> Bool {
        if !isTargetAppRunning {
            print("应用未启动!")
            return false
        }
        guard let app = accessibilityManager.getAppElementByName(targetAppName), let role = accessibilityManager.getElementRole(app), role == "AXApplication" else {
            print("无法获取app元素,请检查!")
            return false
        }
        elementCacheManager.addElement(forKey: "AXApplication", element: app)
        print("app缓存更新成功!")
        return true
    }

    /// 尝试更新窗口缓存, 进程开启但是可能窗口为空
    private func updateWindowCache() -> Bool {
        if !isTargetAppRunning {
            print("app未运行!")
            return false
        }
        // 检查app缓存是否可用
        var app = elementCacheManager.getElement(forKey: "AXApplication")
        // 如果可用则通过app更新

        // 否则重新获取app并更新
        return true
    }

    /// 尝试更新手写工具栏
    private func updateWriteToolButtonsCache() -> Bool {
        // 尝试获取窗口缓存, 并检查缓存是否可用

        // 如果缓存可用则直接获取

        // 否则检查app缓存是否可用,如果可用则通过app获取window并更新

        // 通过获取的window获取button更新缓存
        return false
    }

    private func clearAllElementCache() {
        elementCacheManager.clearWindowCache()
        elementCacheManager.clearButtonCache()
        elementCacheManager.clearElementCache()
    }

    /// 释放监听器资源
    deinit {
        stopRetryTimer()
        clearAllElementCache()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}
