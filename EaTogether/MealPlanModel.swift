//
//  MealPlanModel.swift
//  Original02
//
//  Created by Codex on 2026/05/27.
//

import Foundation
import SwiftData

/// 朝・昼・夜の区分を扱う型です。
enum MealTime: String, CaseIterable, Codable, Identifiable {
    case breakfast = "朝"
    case lunch = "昼"
    case dinner = "夜"

    var id: String { rawValue }
}

/// 食べるかどうかの状態を表す型です。
enum MealStatus: Int, CaseIterable, Codable {
    case undecided
    case home
    case out

    /// 次の状態に切り替えます。
    func next() -> MealStatus {
        switch self {
        case .undecided:
            return .home
        case .home:
            return .out
        case .out:
            return .undecided
        }
    }
}

/// 家族1人分の食事入力データです。
struct MemberMealPlan: Codable, Identifiable, Hashable {
    var id: UUID
    var memberId: String
    var name: String
    var breakfast: MealStatus
    var lunch: MealStatus
    var dinner: MealStatus
    var note: String

    init(
        id: UUID = UUID(),
        memberId: String = UUID().uuidString,
        name: String,
        breakfast: MealStatus = .undecided,
        lunch: MealStatus = .undecided,
        dinner: MealStatus = .undecided,
        note: String = ""
    ) {
        self.id = id
        self.memberId = memberId
        self.name = name
        self.breakfast = breakfast
        self.lunch = lunch
        self.dinner = dinner
        self.note = note
    }

    /// 指定した時間帯の状態を返します。
    func status(for mealTime: MealTime) -> MealStatus {
        switch mealTime {
        case .breakfast:
            return breakfast
        case .lunch:
            return lunch
        case .dinner:
            return dinner
        }
    }

    /// 指定した時間帯の状態を更新します。
    mutating func setStatus(_ status: MealStatus, for mealTime: MealTime) {
        switch mealTime {
        case .breakfast:
            breakfast = status
        case .lunch:
            lunch = status
        case .dinner:
            dinner = status
        }
    }
}

/// 1日分の予定を保存するSwiftDataモデルです。
@Model
final class DayPlan {
    @Attribute(.unique) var groupDayKey: String
    var groupId: String
    var dayKey: String
    var date: Date
    var memberPlans: [MemberMealPlan]

    init(date: Date, groupId: String, memberPlans: [MemberMealPlan]) {
        self.date = date
        self.groupId = groupId
        self.dayKey = DayPlan.dayKey(from: date)
        self.groupDayKey = DayPlan.groupDayKey(groupId: groupId, date: date)
        self.memberPlans = memberPlans
    }

    /// 日付から検索用キーを作成します。
    static func dayKey(from date: Date) -> String {
        let calendar = Calendar.current
        let normalized = calendar.startOfDay(for: date)
        return stableDayKeyFormatter.string(from: normalized)
    }

    /// グループと日付から一意キーを作成します。
    static func groupDayKey(groupId: String, date: Date) -> String {
        "\(groupId)-\(dayKey(from: date))"
    }

    /// 同期向けの日付キーを固定形式で返すフォーマッターです。
    private static let stableDayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 9 * 3600)
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}
