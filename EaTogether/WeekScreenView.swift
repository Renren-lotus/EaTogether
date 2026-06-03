//
//  WeekScreenView.swift
//  Original02
//
//  Created by Codex on 2026/05/27.
//

import SwiftUI

/// 1週間分の予定一覧を表示する画面です。
struct WeekScreenView: View {
    let plans: [DayPlan]
    let onEditDate: (Date) -> Void

    var body: some View {
        let dates = weekDates()

        ScrollView {
            VStack(spacing: 12) {
                ForEach(dates, id: \.self) { date in
                    WeekMealRow(
                        date: date,
                        breakfastCount: mealCount(for: .breakfast, date: date),
                        lunchCount: mealCount(for: .lunch, date: date),
                        dinnerCount: mealCount(for: .dinner, date: date),
                        onEdit: {
                            onEditDate(date)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(AppThemeColor.baseBackground)
    }

    /// 1週間分の日付配列を作ります。
    private func weekDates() -> [Date] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }

    /// 指定日の食数を返します。
    private func mealCount(for mealTime: MealTime, date: Date) -> Int {
        let targetPlan = plans.first(where: { $0.dayKey == DayPlan.dayKey(from: date) })
        guard let targetPlan else { return 0 }
        return targetPlan.memberPlans.filter { $0.status(for: mealTime) == .home }.count
    }
}

/// 1日分の必要食数を表示する行です。
private struct WeekMealRow: View {
    let date: Date
    let breakfastCount: Int
    let lunchCount: Int
    let dinnerCount: Int
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(date.jpMonthDayWeekday)
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Button {
                    onEdit()
                } label: {
                    Label("予定を編集", systemImage: "pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppThemeColor.accent)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                countPill(title: MealTime.breakfast.rawValue, count: breakfastCount)
                countPill(title: MealTime.lunch.rawValue, count: lunchCount)
                countPill(title: MealTime.dinner.rawValue, count: dinnerCount)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppThemeColor.support.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 7, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }

    /// 朝昼夜の食数チップです。
    private func countPill(title: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text("\(count)食")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppThemeColor.accent)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(AppThemeColor.support.opacity(0.45))
        .clipShape(Capsule())
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    WeekScreenView(plans: [], onEditDate: { _ in })
}
