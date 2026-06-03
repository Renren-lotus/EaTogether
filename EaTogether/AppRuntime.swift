//
//  AppRuntime.swift
//  Original02
//
//  Created by Codex on 2026/05/29.
//

import Foundation

/// 実行環境を判定する補助です。
enum AppRuntime {
    /// Xcode Preview実行中かどうかです。
    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
