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
    // 按钮缓存
    private var buttonCache: [AXUIElement] = []

    // MARK: - 键值对缓存管理

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
