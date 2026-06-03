//
//  GroupRealtimeSyncService.swift
//  EaTogether
//
//  Created by Codex on 2026/06/03.
//

import FirebaseCore
import FirebaseFirestore
import Foundation

/// Firebaseに保存する1人分1日分の食事データです。
struct GroupMealEntry {
    var groupId: String
    var dayKey: String
    var date: Date
    var memberId: String
    var memberName: String
    var breakfast: MealStatus
    var lunch: MealStatus
    var dinner: MealStatus
    var note: String
}

/// グループの予定をFirebase Firestoreと同期するサービスです。
final class GroupRealtimeSyncService {
    private let collectionName = "mealPlanEntries"

    /// 指定グループと対象日の予定を取得します。
    func fetchEntries(groupId: String, dayKeys: [String]) async throws -> [GroupMealEntry] {
        guard !groupId.isEmpty else { return [] }
        guard !dayKeys.isEmpty else { return [] }
        guard let database = firestore() else {
            throw GroupRealtimeSyncError.firebaseNotConfigured
        }

        let snapshot = try await database
            .collection(collectionName)
            .whereField("groupId", isEqualTo: groupId)
            .whereField("dayKey", in: dayKeys)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            Self.entry(from: document.data())
        }
        .sorted { $0.date < $1.date }
    }

    /// 指定データをFirebase Firestoreへ保存します。
    func upsert(entry: GroupMealEntry) async throws {
        guard let database = firestore() else {
            throw GroupRealtimeSyncError.firebaseNotConfigured
        }

        try await database
            .collection(collectionName)
            .document(Self.documentId(groupId: entry.groupId, dayKey: entry.dayKey, memberId: entry.memberId))
            .setData([
                "groupId": entry.groupId,
                "dayKey": entry.dayKey,
                "date": Timestamp(date: entry.date),
                "memberId": entry.memberId,
                "memberName": entry.memberName,
                "breakfast": entry.breakfast.rawValue,
                "lunch": entry.lunch.rawValue,
                "dinner": entry.dinner.rawValue,
                "note": entry.note
            ], merge: true)
    }

    /// Firestoreを使える状態なら返します。
    private func firestore() -> Firestore? {
        guard !AppRuntime.isPreview else { return nil }
        guard FirebaseApp.app() != nil else { return nil }
        return Firestore.firestore()
    }

    /// Firestoreの辞書データをアプリ内モデルへ変換します。
    private static func entry(from data: [String: Any]) -> GroupMealEntry? {
        guard
            let groupId = data["groupId"] as? String,
            let dayKey = data["dayKey"] as? String,
            let timestamp = data["date"] as? Timestamp,
            let memberId = data["memberId"] as? String,
            let memberName = data["memberName"] as? String,
            let breakfastRaw = data["breakfast"] as? Int,
            let lunchRaw = data["lunch"] as? Int,
            let dinnerRaw = data["dinner"] as? Int,
            let breakfast = MealStatus(rawValue: breakfastRaw),
            let lunch = MealStatus(rawValue: lunchRaw),
            let dinner = MealStatus(rawValue: dinnerRaw)
        else {
            return nil
        }

        return GroupMealEntry(
            groupId: groupId,
            dayKey: dayKey,
            date: timestamp.dateValue(),
            memberId: memberId,
            memberName: memberName,
            breakfast: breakfast,
            lunch: lunch,
            dinner: dinner,
            note: data["note"] as? String ?? ""
        )
    }

    /// 1ドキュメントに対する一意なIDを作成します。
    private static func documentId(groupId: String, dayKey: String, memberId: String) -> String {
        let raw = "\(groupId)_\(dayKey)_\(memberId)"
        return raw.replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)
    }
}

/// Firebase同期で起きるアプリ用エラーです。
private enum GroupRealtimeSyncError: LocalizedError {
    case firebaseNotConfigured

    var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            return "Firebaseの設定が見つかりません。GoogleService-Info.plistを確認してください。"
        }
    }
}
