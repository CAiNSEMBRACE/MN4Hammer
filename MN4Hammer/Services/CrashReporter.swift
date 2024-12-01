//
//  CrashReporter.swift
//  MN4Hammer
//
//  Created by LinAn on 2024/12/1.
//

import Foundation

class CrashReporter {
    /// 设置崩溃捕获
    static func setup() {
        // Objective-C 异常捕获
        NSSetUncaughtExceptionHandler(globalExceptionHandler)

        // 注册信号处理函数
        signal(SIGABRT, signalHandler)
        signal(SIGILL, signalHandler)
        signal(SIGSEGV, signalHandler)
        signal(SIGFPE, signalHandler)
        signal(SIGBUS, signalHandler)
        signal(SIGPIPE, signalHandler)
    }

    /// 保存崩溃日志到文件
    static func saveCrashLogToFile(_ log: String) {
        guard let logURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("crash_log.txt") else {
            print("Failed to construct file URL")
            return
        }

        print("Crash log file path: \(logURL.path)") // 打印路径
        let logEntry = "\(Date()): \(log)\n"
        do {
            if FileManager.default.fileExists(atPath: logURL.path) {
                let fileHandle = try FileHandle(forWritingTo: logURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(logEntry.data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                try logEntry.write(to: logURL, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Failed to write crash log to file: \(error)")
        }
    }
}

/// 全局的 Objective-C 异常处理函数
private func globalExceptionHandler(exception: NSException) {
    let stack = exception.callStackSymbols.joined(separator: "\n")
    let crashLog = "[Crash] \(exception.name.rawValue): \(exception.reason ?? "Unknown")\n\(stack)"
    CrashReporter.saveCrashLogToFile(crashLog)
}

/// 全局的信号处理函数
private func signalHandler(signal: Int32) {
    let crashLog = "[Crash] Signal \(signal) detected"
    CrashReporter.saveCrashLogToFile(crashLog)
    exit(signal)
}
