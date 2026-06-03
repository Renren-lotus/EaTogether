//
//  LocalGroupSession.swift
//  Original02
//
//  Created by Codex on 2026/05/29.
//

import Foundation
import Observation

/// アプリ内のログインユーザーとグループ情報を保持します。
@Observable
final class LocalGroupSession {
    var currentUserId: String {
        didSet {
            defaults.set(currentUserId, forKey: Keys.currentUserId)
        }
    }

    var currentUserName: String {
        didSet {
            defaults.set(currentUserName, forKey: Keys.currentUserName)
        }
    }

    var groupId: String {
        didSet {
            defaults.set(groupId, forKey: Keys.groupId)
        }
    }

    var groupName: String {
        didSet {
            defaults.set(groupName, forKey: Keys.groupName)
        }
    }

    var isSetupCompleted: Bool {
        !currentUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !groupId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayGroupName: String {
        let trimmed = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "みんなのごはん" : trimmed
    }

    private let defaults = UserDefaults.standard

    init() {
        let savedUserId = defaults.string(forKey: Keys.currentUserId)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let savedName = defaults.string(forKey: Keys.currentUserName)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let savedGroupId = defaults.string(forKey: Keys.groupId)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let savedGroupName = defaults.string(forKey: Keys.groupName)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        currentUserId = savedUserId.isEmpty ? UUID().uuidString : savedUserId
        currentUserName = savedName
        groupId = savedGroupId
        groupName = savedGroupName

        defaults.set(currentUserId, forKey: Keys.currentUserId)
    }

    /// 新しいグループを作成します。
    func createGroup(userName: String, groupName: String) {
        currentUserName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        groupId = Self.generateGroupId()
        self.groupName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 既存グループに参加します。
    func joinGroup(userName: String, groupId: String, groupName: String = "") {
        currentUserName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.groupId = groupId
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        self.groupName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 表示用グループ名を更新します。
    func updateGroupName(_ groupName: String) {
        self.groupName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// グループ参加状態だけを解除します。
    func clearGroup() {
        groupId = ""
        groupName = ""
    }

    /// グループIDをランダム生成します。
    private static func generateGroupId(length: Int = 6) -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).compactMap { _ in
            chars.randomElement()
        })
    }

    private enum Keys {
        static let currentUserId = "group.currentUserId"
        static let currentUserName = "group.currentUserName"
        static let groupId = "group.groupId"
        static let groupName = "group.groupName"
    }
}
