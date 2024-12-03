//
//  ElementCacheManager.swift
//  MN4Hammer
//
//  Created by LinAn on 2024/11/30.
//
import Cocoa

class ElementCacheManager {
    // 键值对缓存
    private var elementCache: [String: AXUIElement] = [:]

    // 窗口缓存
    private var windowCache: [AXUIElement] = []
    private var mainWindowIndex: Int = -1
    private var multiWindowMode: Bool = false // 多窗口模式默认关闭,暂时不支持

    // 按钮缓存
    private var buttonCache: [AXUIElement] = []

    // MARK: - 键值对缓存管理

    /// 添加app缓存
    func addApp(_ app: AXUIElement) {
        addElement(forKey: "AXApplication", element: app)
    }

    /// 获取app缓存
    func getApp() -> AXUIElement? {
        return getElement(forKey: "AXApplication")
    }

    /// 删除app缓存
    func removeApp() {
        removeElement(forKey: "AXApplication")
    }

    /// 添加键值对到缓存
    func addElement(forKey key: String, element: AXUIElement) {
        elementCache[key] = element
    }

    /// 获取指定键的元素
    func getElement(forKey key: String) -> AXUIElement? {
        // 这里如果不存在会返回nil
        return elementCache[key]
    }

    /// 删除指定键的元素
    func removeElement(forKey key: String) {
        elementCache.removeValue(forKey: key)
    }

    /// 清空键值对缓存
    func clearElementCache() {
        elementCache.removeAll()
    }

    /// 检查是否存在某个键
    func containsKey(_ key: String) -> Bool {
        return elementCache.keys.contains(key)
    }

    // MARK: - 窗口缓存管理

    /// 初始化窗口缓存
    func initializeWindowCache() {
        windowCache.removeAll()
        mainWindowIndex = -1
        multiWindowMode = false
    }

    /// 添加窗口到缓存
    func addWindow(_ window: AXUIElement) {
        if !multiWindowMode {
            // 如果不是多窗口模式, 直接存入键值对
            addElement(forKey: "AXWindow", element: window)

        } else if !windowCache.contains(where: { $0 == window }) {
            windowCache.append(window)
        }
    }

    /// 获取所有窗口
    func getAllWindows() -> [AXUIElement]? {
        if !multiWindowMode {
            // 如果不是多窗口模式, 不应该调用这个函数
            return nil
        }
        guard windowCache.count > 0 else {
            return nil
        }
        return windowCache
    }

    /// 获取主窗口,或被聚焦窗口
    func getMainWindow() -> AXUIElement? {
        if !multiWindowMode {
            // 如果不是多窗口模式, 直接从字典中查找返回
            return getElement(forKey: "AXWindow")
        }
        guard windowCache.count > 0, mainWindowIndex != -1, mainWindowIndex < windowCache.count else {
            return nil
        }
        return windowCache[mainWindowIndex]
    }

    /// 检查窗口是否已缓存
    func isWindowCached(_ window: AXUIElement) -> Bool {
        return windowCache.contains(where: { $0 == window })
    }

    /// 删除指定窗口
    func removeWindow(_ window: AXUIElement) {
        windowCache.removeAll(where: { $0 == window })
    }

    /// 删除主窗口
    func removeMainWindow() {
        removeElement(forKey: "AXWindow")
    }

    /// 清空窗口缓存
    func clearWindowCache() {
        windowCache.removeAll()
        mainWindowIndex = -1
        multiWindowMode = false
    }

    // MARK: - 按钮缓存管理

    /// 初始化按钮缓存
    func initializeButtonCache() {
        buttonCache.removeAll()
    }

    /// 添加按钮到缓存
    func addButton(_ button: AXUIElement) {
        if !buttonCache.contains(where: { $0 == button }) {
            buttonCache.append(button)
        }
    }

    /// 获取所有按钮
    func getAllButtons() -> [AXUIElement]? {
        guard buttonCache.count > 0 else {
            return nil
        }
        return buttonCache
    }

    /// 检查按钮是否已缓存
    func isButtonCached(_ button: AXUIElement) -> Bool {
        return buttonCache.contains(where: { $0 == button })
    }

    /// 删除按钮
    func removeButton(_ button: AXUIElement) {
        buttonCache.removeAll(where: { $0 == button })
    }

    /// 清空按钮缓存
    func clearButtonCache() {
        buttonCache.removeAll()
    }
}
