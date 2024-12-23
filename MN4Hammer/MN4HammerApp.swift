//
//  MN4HammerApp.swift
//  MN4Hammer
//
//  Created by LinAn on 2024/11/24.
//

import AppKit
import ApplicationServices
import CoreFoundation
import SwiftUI

@main
struct MN4HammerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
