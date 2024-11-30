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
    func getFocusedWindow(in appElement: AXUIElement) -> AXUIElement? {
        
        return nil
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

    //检查传入element是否支持点击事件
    func isPressable(_ element: AXUIElement) -> Bool {
        var actions: CFArray?
        let result = AXUIElementCopyActionNames(element, &actions)
        if result == .success, let actionsArray = actions as? [CFString] {
            print("Supported actions: \(actionsArray)")
            return actionsArray.contains(kAXPressAction as CFString)
        }
        return false
    }
    
}
