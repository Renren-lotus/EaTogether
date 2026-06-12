//
//  MealReminderManager.swift
//  EaTogether
//
//  Created by Codex on 2026/06/05.
//

import Foundation
import Observation
import UserNotifications

/// ご飯予定の記録忘れ通知を管理します。
@MainActor
@Observable
final class MealReminderManager {
    var isReminderEnabled: Bool
    var reminderTime: Date
    var statusMessage = ""

    private let defaults = UserDefaults.standard
    private let notificationCenter = UNUserNotificationCenter.current()

    init() {
        isReminderEnabled = defaults.bool(forKey: Keys.isReminderEnabled)

        if let savedTime = defaults.object(forKey: Keys.reminderTime) as? Date {
            reminderTime = savedTime
        } else {
            reminderTime = Self.defaultReminderTime()
        }
    }

    /// 通知設定の現在状態を確認します。
    func refreshAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        if settings.authorizationStatus == .denied {
            statusMessage = "通知が許可されていません。iPhoneの設定アプリから通知を許可してください。"
        }
    }

    /// 通知のオン・オフを切り替えます。
    func setReminderEnabled(_ isEnabled: Bool) async {
        isReminderEnabled = isEnabled
        defaults.set(isEnabled, forKey: Keys.isReminderEnabled)

        if isEnabled {
            await requestPermissionAndSchedule()
        } else {
            cancelReminder()
            statusMessage = "通知をオフにしました。"
        }
    }

    /// 通知する時刻を更新します。
    func setReminderTime(_ time: Date) async {
        reminderTime = time
        defaults.set(time, forKey: Keys.reminderTime)

        guard isReminderEnabled else {
            statusMessage = "通知時間を保存しました。"
            return
        }

        await requestPermissionAndSchedule()
    }

    /// 通知許可を求めて、許可されたら毎日の通知を予約します。
    private func requestPermissionAndSchedule() async {
        do {
            let isAllowed = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            guard isAllowed else {
                isReminderEnabled = false
                defaults.set(false, forKey: Keys.isReminderEnabled)
                statusMessage = "通知が許可されませんでした。"
                return
            }

            try await scheduleDailyReminder()
            statusMessage = "毎日の通知を設定しました。"
        } catch {
            isReminderEnabled = false
            defaults.set(false, forKey: Keys.isReminderEnabled)
            statusMessage = "通知の設定に失敗しました。もう一度試してください。"
        }
    }

    /// 毎日同じ時刻に通知する予約を作ります。
    private func scheduleDailyReminder() async throws {
        cancelReminder()

        let content = UNMutableNotificationContent()
        content.title = "ご飯の予定が未定です！"
        content.body = "今日の朝・昼・夜の予定を入力しましょう。"
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    /// 予約済みの記録忘れ通知を取り消します。
    private func cancelReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])
    }

    /// 最初に表示する通知時刻を作ります。
    private static func defaultReminderTime() -> Date {
        var components = DateComponents()
        components.hour = 20
        components.minute = 0

        return Calendar.current.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTime
        ) ?? Date()
    }

    private static let notificationIdentifier = "dailyMealPlanReminder"

    private enum Keys {
        static let isReminderEnabled = "mealReminder.isEnabled"
        static let reminderTime = "mealReminder.time"
    }
}
