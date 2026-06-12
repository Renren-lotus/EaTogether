//
//  DeviceUserIdentifier.swift
//  EaTogether
//
//  Created by Codex on 2026/06/08.
//

import Foundation
import UIKit

/// 端末ごとに安定したユーザーIDを返します。
enum DeviceUserIdentifier {
    private static let fallbackKey = "group.fallbackDeviceUserId"

    /// 現在の端末向けユーザーIDを返します。
    static func current(defaults: UserDefaults) -> String {
        if let vendorId = UIDevice.current.identifierForVendor?.uuidString,
           !vendorId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "device-\(vendorId.lowercased())"
        }

        let savedFallback = defaults.string(forKey: fallbackKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !savedFallback.isEmpty {
            return savedFallback
        }

        let newFallback = "device-\(UUID().uuidString.lowercased())"
        defaults.set(newFallback, forKey: fallbackKey)
        return newFallback
    }
}
