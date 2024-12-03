//
//  ErrorManager.swift
//  MN4Hammer
//
//  Created by LinAn on 2024/12/1.
//

import Foundation

enum AppError: Error {
    case invalidInput(reason: String)
    case accessibilityFailure(reason: String)
    case backgroundTaskError(reason: String)
    case unknown

    var description: String {
        switch self {
        case let .invalidInput(reason): return "Invalid Input: \(reason)"
        case let .accessibilityFailure(reason): return "Accessibility Failure: \(reason)"
        case let .backgroundTaskError(reason): return "Background Task Error: \(reason)"
        case .unknown: return "Unknown Error"
        }
    }
}

class ErrorManager {
    static let shared = ErrorManager()

    func handleError(_ error: AppError, function: String = #function, file: String = #file, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[Error] \(error.description) | \(fileName) -> \(function) [Line \(line)]"
        LogHelper.logError(logMessage)
        saveErrorToFile(logMessage)
    }

    private func saveErrorToFile(_ message: String) {
        guard let logURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("error_log.txt") else { return }
        let logEntry = "\(Date()): \(message)\n"
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
            print("Failed to write error to file: \(error.localizedDescription)")
        }
    }
}
