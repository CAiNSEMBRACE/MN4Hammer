//
//  AccessibilityManager.swift
//  MN4Hammer
//
//  Created by LinAn on 2024/11/30.
//
import AppKit

///这个类主要用于进行与Accessibility API的交互
///直接操作AXUIElement
class AccessibilityManager {
    
    //检查是否拥有Accessibility权限
    func isAccessibilityPermissionEnabled() -> Bool {
        print("辅助功能权限未启用, 请在 系统设置 > 隐私与安全 > 辅助功能 中启用.")
        return AXIsProcessTrusted()
    }
    
    //根据appName找到运行的app, 得到对应的 AXUIElement 对象
    func getAppElementByName(_ appName: String) -> AXUIElement? {
        
        //固定写法,获取当前运行的app列表: [NSRunningApplication]
        let runningApps = NSWorkspace.shared.runningApplications
        
        //守卫 guard A else { B } A正确运行 则 继续执行 否则执行B
        guard let targetApp = runningApps.first(where: { $0.localizedName == appName }),
              let pid = targetApp.processIdentifier as pid_t? else {
            return nil
        }
        
        //固定用法通过提供pid得到对应的AXUIElment对象, 并且返回出去
        return AXUIElementCreateApplication(pid)
    }
    
    ///根据提供的appAXUIElement, 获取所有的窗口(windows)
    func getAllWindows(in appElement: AXUIElement) -> [AXUIElement]? {
        var windowsValue: CFTypeRef?
        let windowsError = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
        
        guard windowsError == .success, let windows = windowsValue as? [AXUIElement], !windows.isEmpty else {
            return nil
        }
        return windows
    }
    
    //通过app元素获取聚焦窗口
    func getFocusedWindow(from application: AXUIElement) -> AXUIElement? {
        var focusedWindow: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(application, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        guard error == .success else {
            print("Failed to retrieve focused window. Error code: \(error.rawValue)")
            return nil
        }
        
        let window = focusedWindow as! AXUIElement
        guard "AXWindow" == getElementRole(window) else {
            return nil
        }
        
        return window
    }
    
    // 检查元素是否被聚焦, 一般情况下检查window元素
    func isElementFocused(_ element: AXUIElement) -> Bool {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, kAXFocusedAttribute as CFString, &value)
        
        if error == .success, let isFocused = value as? Bool {
            return isFocused
        } else {
            print("Failed to retrieve AXFocused attribute. Error code: \(error.rawValue)")
            return false
        }
    }
    
    //检查element是否有效
    func isElementValid(_ element: AXUIElement) -> Bool {
        //通过获取element的role来检查是否有效
        var isValid = false
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &value)
        if result == .success {
            isValid = true
        }
        return isValid
    }
    
    //触发点击操作
    func performClick(on element: AXUIElement) -> Bool {
        let result = AXUIElementPerformAction(element, kAXPressAction as CFString)
        if result == .success {
            print("点击成功. pc01")
            return true
        } else {
            print("点击失败. Error: \(result.rawValue) pc02")
            return false
        }
    }
    
    //检查element是否支持点击事件
    func isPressable(_ element: AXUIElement) -> Bool {
        var actions: CFArray?
        let result = AXUIElementCopyActionNames(element, &actions)
        if result == .success, let actionsArray = actions as? [CFString] {
            print("Supported actions: \(actionsArray)")
            return actionsArray.contains(kAXPressAction as CFString)
        }
        return false
    }
    
    //获取元素Size, CGSize格式, 伴随多种测试
    func getElementSize(_ button: AXUIElement) -> CGSize? {
        var sizeValue: CFTypeRef?

        // 获取 kAXSizeAttribute 属性值
        let sizeError = AXUIElementCopyAttributeValue(button, kAXSizeAttribute as CFString, &sizeValue)
        guard sizeError == .success, let axValue = sizeValue else {
            print("无法通过kAXSizeAttribute获取到AXSize数据: \(sizeError.rawValue)")
            return nil
        }
        
        //检查数据格式
        guard AXValueGetType(axValue as! AXValue) == .cgSize else {
            print("axValue并不是CGSize格式数据.")
            return nil
        }
        
        //提取数据
        var size = CGSize.zero
        guard AXValueGetValue(axValue as! AXValue, .cgSize, &size) else {
            print("无法从 AXValue 中提取 CGSize.")
            return nil
        }
        
        return size
    }
    
    //获取元素Frame, CGRect格式
    func getElementFrameWithFrameAttribute(_ element: AXUIElement) -> CGRect? {
        var frameValue: CFTypeRef?
        let frameError = AXUIElementCopyAttributeValue(element, "AXFrame" as CFString, &frameValue)

        if frameError == .success, let axValue = frameValue, AXValueGetType(axValue as! AXValue) == .cgRect {
            var frame = CGRect.zero
            AXValueGetValue(axValue as! AXValue, .cgRect, &frame)
            return frame
        }

        return nil
    }
    
    // 获取获取元素role数据
    func getElementRole(_ element: AXUIElement) -> String? {
        
        var roleValue: CFTypeRef?
        let roleError = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        if roleError == .success, let role = roleValue as? String{
            return role
        }
        return nil
    }
    
    //检查element支持的参数获取, 供测试使用
    func getElementAttributes(_ element: AXUIElement) {
        var attributes: CFArray?
        let result = AXUIElementCopyAttributeNames(element, &attributes)
        
        if result == .success, let attrArray = attributes as? [CFString] {
            print("元素支持参数: \(attrArray)")
        } else {
            print("获取参数失败: \(result.rawValue)")
        }
    }
    
    /// 递归获取视图层级信息
    /// 性能消耗极大, 仅供测试使用
    func getElementHierarchy(in element: AXUIElement, depth: Int, maxDepth: Int) -> String {
        guard depth <= maxDepth else { return "" }
        
        var output = String(repeating: "  |", count: depth - 1) // 缩进
        output += "- 层级 \(depth):\n"
        
        // 获取元素的角色
        var role: CFTypeRef?
        let roleError = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        let roleDescription = (roleError == .success && role != nil) ? (role as! String) : "未知角色"
        output += String(repeating: "  |", count: depth) + "角色: \(roleDescription)\n"
        
        // 获取元素的标题
        var title: CFTypeRef?
        let titleError = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &title)
        if titleError == .success, let title = title as? String {
            output += String(repeating: "  |", count: depth) + "标题: \(title)\n"
        }
        
        // 获取元素的尺寸
        var sizeValue: CFTypeRef?
        let sizeError = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue)
        if sizeError == .success, let size = sizeValue as? CGSize {
            output += String(repeating: "  |", count: depth) + "尺寸: \(size.width) x \(size.height)\n"
        } else {
            output += String(repeating: "  |", count: depth) + "尺寸: 无法访问或无尺寸属性。\n"
        }
        
        // 获取子视图
        var childrenValue: CFTypeRef?
        let childrenError = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue)
        if childrenError == .success, let childrenArray = childrenValue as? [AXUIElement] {
            output += String(repeating: "  |", count: depth) + "子视图数量: \(childrenArray.count)\n"
            for child in childrenArray {
                output += getElementHierarchy(in: child, depth: depth + 1, maxDepth: maxDepth)
            }
        } else {
            output += String(repeating: "  |", count: depth) + "无子视图或无法访问子视图。\n"
        }
        
        return output
    }
}
