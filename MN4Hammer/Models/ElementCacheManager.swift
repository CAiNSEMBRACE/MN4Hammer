//
//  ElementCacheManager.swift
//  MN4Hammer
//
//  Created by LinAn on 2024/11/30.
//
import AppKit

class ElementCacheManager {
    private var cache: [String: AXUIElement] = [:]

    func getElement(forKey key: String) -> AXUIElement? {
        return cache[key]
    }

    func addElement(_ element: AXUIElement, forKey key: String) {
        cache[key] = element
    }

    func isElementInCacheValid(forKey key: String, using manager: AccessibilityManager) -> Bool {
        guard let element = cache[key] else { return false }
        return manager.isElementValid(element)
    }
}
