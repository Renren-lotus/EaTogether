//
//  Date+JapaneseDisplay.swift
//  Original02
//
//  Created by Codex on 2026/05/29.
//

import Foundation

/// 日付を日本語表示に変換する補助です。
extension Date {
    /// 「5月29日」の形式で返します。
    var jpMonthDay: String {
        AppDateFormatter.jpMonthDay.string(from: self)
    }

    /// 「5月29日(金)」の形式で返します。
    var jpMonthDayWeekday: String {
        AppDateFormatter.jpMonthDayWeekday.string(from: self)
    }
}

/// 日付フォーマッターをまとめる型です。
private enum AppDateFormatter {
    static let jpMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    static let jpMonthDayWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "M月d日(E)"
        return formatter
    }()
}
