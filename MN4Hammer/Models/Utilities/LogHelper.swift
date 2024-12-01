//
//  LogHelper.swift
//  MN4Hammer
//
//  Created by LinAn on 2024/12/1.
//

import os

struct LogHelper {
    private static let logger = Logger(subsystem: "com.mn4hammer.app", category: "General")

    static func logDebug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    static func logError(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }

    static func logInfo(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }
}
