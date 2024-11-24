//
//  ContentView.swift
//  MN4Hammer
//
//  Created by LinAn on 2024/11/26.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var appName: String = "MarginNote 4"
    @State private var buttonIndex: String = "0"
    @State private var result: String = "等待结果..."
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("输入应用名称", text: $appName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack {
                Button("展示窗口层级信息") {
                    result = getWindowInfo(for: appName)
                }
                .padding()
                Button("展示按钮同级信息") {
                    result = getFourthLayerInfo(appName)
                }
                .padding()
                Button("展示笔刷按钮信息") {
                    
                }
                .padding()
                
            }
            .padding()
            TextField("输入点击按钮编号, 从0开始", text: $buttonIndex)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack {
                Button("点击按钮") {
                    action4DebugOnly()
                }
                .padding()
            }
            ScrollView {
                Text(result)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
    }
    
    //用于测试点击按钮
    func action4DebugOnly() {
        
        guard let app = getAppElementByName(self.appName) else {
            print("App not found! a4do01")
            return
        }
        
        guard let windows = getWindows(in: app), windows.count > 0 else {
            print("Window not found! a4do02")
            return
        }
        
        let window = windows[0]
        
        guard let parent = getParentOfWriteToolButtons(in: window) else {
            print("Parent not found! a4do03")
            return
        }
        
        guard let buttons = getWriteToolButtons(in: parent), buttons.count > 0 else {
            print("Button not found! a4do04")
            return
        }
        
        clickButtonWithIndex(on: buttons,index: self.buttonIndex)
        
    }
    
    func clickButtonWithIndex(on buttons: [AXUIElement], index: String) {
        guard let indexOfButton = Int(index) else {
            print("输入的index格式不正确! cbwi01")
            return
        }
        
        guard indexOfButton >= 0 && indexOfButton < buttons.count else {
            print("输入的index超出范围! cbwi02")
            return
        }
        
        let button = buttons[indexOfButton]
        
        guard isPressable(button) else {
            print("该button无法被点击, 请检查输入的element格式. cbwi03")
            return
        }
        
        performClick(on: button)
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
    
    //触发传入的element的点击事件
    func performClick(on element: AXUIElement) {
        let result = AXUIElementPerformAction(element, kAXPressAction as CFString)
        if result == .success {
            print("按钮点击成功. pc01")
        } else {
            print("Failed to perform click action. Error: \(result.rawValue) pc02")
        }
    }
    
    ///根据提供的appAXUIElement展示app窗口信息
    func getWindowInfo(for appName: String) -> String {
        guard AXIsProcessTrusted() else {
            return "辅助功能权限未启用，请在 系统设置 > 隐私与安全 > 辅助功能 中启用。"
        }
        
        //调用函数获取app AXUIElement
        guard let appAXUIElement: AXUIElement = getAppElementByName(appName) else {
            //如果得到的数据不是AXUIElement 说明没有找到对应app
            return "App not found!"
        }
        
        //CFTyperRef? 可选的CFTypeRef类型
        //CFTypeRef是Core Foundation框架中的一种通用的类型引用, 可以用来表示多种不同类型的数据
        //CFString是Core Foundation框架中常用的字符串格式
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(appAXUIElement, kAXWindowsAttribute as CFString, &value)
        
        guard error == .success, let windows = value as? [AXUIElement], !windows.isEmpty else {
            return "未找到任何窗口，或无法访问窗口信息。"
        }
        
        var output = "检测到 \(windows.count) 个窗口：\n"
        for (index, window) in windows.enumerated() {
            output += "\n窗口 \(index + 1):\n"
            output += getElementHierarchy(window, depth: 1, maxDepth: 4)
        }
        
        return output
    }
    
    //通过父元素得到手写工具栏按钮列表
    func getWriteToolButtons(in parentElement: AXUIElement) -> [AXUIElement]? {
        var buttons: [AXUIElement] = []

        guard let children = getElementChildrenList(parentElement) else {
            print("无法获取children元素, 请检查传入元素是否正确! gwtb01")
            return nil
        }
        
        for child in children {
            var childValue: CFTypeRef?
            let childError = AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &childValue)
            if childError == .success, let childRole = childValue as? String, childRole == "AXButton", isAXButtonWithCGSize(child, 40, 40, 0.01) {
                buttons.append(child)
            }
        }
        print("获取到buttons数量为: \(buttons.count) gwtb02")
        
        guard buttons.count > 0 else {
            print("未获取到足够的button元素, 请检查. gwtb03")
            return nil
        }
        
        return buttons
    }
    
    //通过窗口元素得到手写工具父元素
    func getParentOfWriteToolButtons(in windowElement: AXUIElement) -> AXUIElement? {
        
        ///根据检查层级信息, 得知手写工具栏按钮层次信息为
        ///AXWindow->AXGroup->AXGroup->AXButton
        ///遂根据层级依次查找
        guard let layer2Elements: [AXUIElement] = getElementChildrenList(windowElement) else {
            print("窗口为空, 请检查获取的AXWindow是否出错. gpowtb01")
            return nil
        }
        //检索第二层中的AXGroup
        var layer2AXGroups: [AXUIElement] = [] //假设存在多个
        for layer2Element in layer2Elements {
            // 获取角色
            var roleValue: CFTypeRef?
            let roleError = AXUIElementCopyAttributeValue(layer2Element, kAXRoleAttribute as CFString, &roleValue)
            if roleError == .success, let role = roleValue as? String, role == "AXGroup" {
                layer2AXGroups.append(layer2Element)
            }
        }
        
        //这里只选取layer2第一个AXGroup
        guard layer2AXGroups.count > 0 else {
            print("layer2中无AXGroup, 请检查父元素windowElement是否正确. gpowtb02")
            return nil
        }
        let layer2AXGroup: AXUIElement = layer2AXGroups[0]
        
        //获取第三层的元素
        guard let layer3Elements: [AXUIElement] = getElementChildrenList(layer2AXGroup) else {
            print("第三层无数据, 检查传入的父元素是否错位. gpowtb03")
            return nil
        }
        
        //检索第三层的AXGroup
        var layer3AXGroups: [AXUIElement] = [] //假设有多个
        for layer3Element in layer3Elements {
            var roleValue: CFTypeRef?
            let roleError = AXUIElementCopyAttributeValue(layer3Element, kAXRoleAttribute as CFString, &roleValue)
            if roleError == .success, let role = roleValue as? String, role == "AXGroup" {
                layer3AXGroups.append(layer3Element)
            }
        }
        
        //检查是否成功检索到AXGroup, 这里只选择第三层第一个AXGroup
        guard layer3AXGroups.count > 0 else {
            print("layer3中无AXGroup, 请检查父元素layer3Elements是否正确. gpowtb04")
            return nil
        }
        
        //得到writeToolButtons的父元素-位于第三层的AXGroup
        let layer3AXGroup: AXUIElement = layer3AXGroups[0]
        
        return layer3AXGroup
    }
    
    ///根据提供的appAXUIElement, 获取所有的窗口(windows)
    func getWindows(in appElement: AXUIElement) -> [AXUIElement]? {
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
    
    ///获取MarginNote 4 手写工具栏所在层次信息, 简称第四层信息
    func getFourthLayerInfo(_ appName: String) -> String {
        
        guard let app: AXUIElement = getAppElementByName(appName) else {
            return "app未启动, 或检查传入的appName是否正确."
        }
        
        guard let windows: [AXUIElement] = getWindows(in: app) else {
            return "找不到窗口, 请检查app窗口是否可见."
        }
        
        //这里暂时只查找第一个window
        let window = windows[0]
        
        ///根据检查层级信息, 得知手写工具栏按钮层次信息为
        ///AXWindow->AXGroup->AXGroup->AXButton
        ///遂根据层级依次查找
        guard let layer2Elements: [AXUIElement] = getElementChildrenList(window) else {
            return "窗口为空, 请检查获取的AXWindow是否出错."
        }
        
        //检索第二层中的AXGroup
        var layer2AXGroups: [AXUIElement] = [] //假设存在多个
        for layer2Element in layer2Elements {
            // 获取角色
            var roleValue: CFTypeRef?
            let roleError = AXUIElementCopyAttributeValue(layer2Element, kAXRoleAttribute as CFString, &roleValue)
            if roleError == .success, let role = roleValue as? String, role == "AXGroup" {
                layer2AXGroups.append(layer2Element)
            }
        }
        
        //这里只在layer2第一个axgroup中寻找
        //即第三层
        let layer2AXGroup: AXUIElement = layer2AXGroups[0]
        
        guard let layer3Elements: [AXUIElement] = getElementChildrenList(layer2AXGroup) else {
            return "第三层无数据, 检查传入的父元素是否错位"
        }
        
        //检索第三层的AXGroup
        var layer3AXGroups: [AXUIElement] = [] //假设有多个
        for layer3Element in layer3Elements {
            var roleValue: CFTypeRef?
            let roleError = AXUIElementCopyAttributeValue(layer3Element, kAXRoleAttribute as CFString, &roleValue)
            if roleError == .success, let role = roleValue as? String, role == "AXGroup" {
                layer3AXGroups.append(layer3Element)
            }
        }
        
        //这里只选择第三层第一个AXGroup
        let layer3AXGroup: AXUIElement = layer3AXGroups[0]
        guard let  layer4Elements: [AXUIElement] = getElementChildrenList(layer3AXGroup) else {
            return "第四层为空, 检查传入的父数据是否错位"
        }
        
        //检索第四层中的AXButton
        var layer4AXButtons: [AXUIElement] = []
        for layer4Element in layer4Elements {
            var roleValue: CFTypeRef?
            let roleError = AXUIElementCopyAttributeValue(layer4Element, kAXRoleAttribute as CFString, &roleValue)
            if roleError == .success, let role = roleValue as? String, role == "AXButton", isAXButtonWithCGSize(layer4Element, 40, 40, 0.01) {
                layer4AXButtons.append(layer4Element)
            }
        }
        
        var buttonInfo: String = ""
        //检索完毕, 尝试输出button编号和size
        for (index, layer4AXButton) in layer4AXButtons.enumerated() {
            
            guard let rect: CGRect = getElementFrameWithFrameAttribute(layer4AXButton) else {
                buttonInfo += "Button \(index): 无法获取位置信息\n"
                continue
            }
            
            guard let size: CGSize = getButtonSizeWithSizeAttribute(layer4AXButton) else {
                buttonInfo += "Button \(index): 无法获取尺寸信息\n"
                continue
            }
            
            buttonInfo += "Button \(index): X: \(rect.origin.x), Y: \(rect.origin.y), 宽 \(size.width), 高 \(size.height)\n"
        }
        
        return buttonInfo
    }
    
    func isAXButtonWithCGSize(_ element: AXUIElement, _ w: CGFloat, _ h: CGFloat, _ toleranceRange: CGFloat) -> Bool {
        //判断是否满足筛选条件
        guard let size: CGSize = getButtonSizeWithSizeAttribute(element) else {
            print("buttonSize筛选无法获取size")
            return false
        }

        return abs(size.width - w) < toleranceRange && abs(size.height - h) < toleranceRange
    }
    
    //检查element支持的参数获取
    func getElementAttributes(_ element: AXUIElement) {
        var attributes: CFArray?
        let result = AXUIElementCopyAttributeNames(element, &attributes)
        
        if result == .success, let attrArray = attributes as? [CFString] {
            print("Attributes for element: \(attrArray)")
        } else {
            print("Failed to retrieve attributes: \(result.rawValue)")
        }
    }
    
    //伴随检测通过AXSize获取CGSize
    func getButtonSizeWithSizeAttribute(_ button: AXUIElement) -> CGSize? {
        var sizeValue: CFTypeRef?

        // 获取 kAXSizeAttribute 属性值
        let sizeError = AXUIElementCopyAttributeValue(button, kAXSizeAttribute as CFString, &sizeValue)

        if sizeError == .success, let axValue = sizeValue {
            // 确认 AXValue 的类型是 CGSize
            if AXValueGetType(axValue as! AXValue) == .cgSize {
                var size = CGSize.zero //用于初始化一个长宽均为0的CGSize
                if AXValueGetValue(axValue as! AXValue, .cgSize, &size) {
                    return size
                } else {
                    print("Failed to extract CGSize from AXValue")
                }
            } else {
                print("AXValue is not of type CGSize")
            }
        } else {
            print("Failed to retrieve kAXSizeAttribute: \(sizeError.rawValue)")
        }
        return nil
    }
    
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
    
    
    /// 递归获取视图层级信息
    func getElementHierarchy(_ element: AXUIElement, depth: Int, maxDepth: Int) -> String {
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
                output += getElementHierarchy(child, depth: depth + 1, maxDepth: maxDepth)
            }
        } else {
            output += String(repeating: "  |", count: depth) + "无子视图或无法访问子视图。\n"
        }
        
        return output
    }
    
    //根据提供的AXUIElement 得到 孩子对象列表或nil
    func getElementChildrenList(_ element: AXUIElement) -> [AXUIElement]? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value)
        guard error == .success, value != nil, let children = value as? [AXUIElement] else {
            return nil
        }
        return children
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
    
}

