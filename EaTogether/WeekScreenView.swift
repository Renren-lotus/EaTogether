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
    let onOpenEditorForDate: (Date) -> Void

    var body: some View {
        let dates = weekDates()

        ScrollView {
            VStack(spacing: 12) {
                ForEach(dates, id: \.self) { date in
                    let targetPlan = plan(for: date)

                    NavigationLink {
                        WeekDayDetailView(
                            date: date,
                            memberPlans: targetPlan?.memberPlans ?? [],
                            onOpenEditor: {
                                onOpenEditorForDate(date)
                            }
                        )
                    } label: {
                        WeekMealRow(
                            date: date,
                            breakfastCount: mealCount(for: .breakfast, date: date),
                            lunchCount: mealCount(for: .lunch, date: date),
                            dinnerCount: mealCount(for: .dinner, date: date)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(AppThemeColor.baseBackground)
    }

    /// 指定日の予定データを返します。
    private func plan(for date: Date) -> DayPlan? {
        plans.first(where: { $0.dayKey == DayPlan.dayKey(from: date) })
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(date.jpMonthDayWeekday)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(weekdayColor)

                Spacer()

                Label("詳細", systemImage: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppThemeColor.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppThemeColor.support.opacity(0.9))
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                countPill(title: MealTime.breakfast.rawValue, count: breakfastCount)
                countPill(title: MealTime.lunch.rawValue, count: lunchCount)
                countPill(title: MealTime.dinner.rawValue, count: dinnerCount)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.white, AppThemeColor.secondaryCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppThemeColor.support.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: AppThemeColor.accent.opacity(0.08), radius: 14, x: 0, y: 5)
    }

    /// 曜日に合わせた日付の文字色を返します。
    private var weekdayColor: Color {
        let weekday = Calendar.current.component(.weekday, from: date)

        switch weekday {
        case 1:
            return .red
        case 7:
            return .blue
        default:
            return .primary
        }
    }

    /// 朝昼夜の食数チップです。
    private func countPill(title: String, count: Int) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Text("\(count)食")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppThemeColor.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(AppThemeColor.support.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// 週画面から開く1日分の確認画面です。
private struct WeekDayDetailView: View {
    let date: Date
    let memberPlans: [MemberMealPlan]
    let onOpenEditor: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                WeekDaySummaryCard(
                    breakfastCount: mealCount(for: .breakfast),
                    lunchCount: mealCount(for: .lunch),
                    dinnerCount: mealCount(for: .dinner)
                )

                editButton

                if sortedMemberPlans.isEmpty {
                    emptyStateCard
                } else {
                    ForEach(sortedMemberPlans) { memberPlan in
                        WeekMemberStatusCard(memberPlan: memberPlan)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(AppThemeColor.baseBackground)
        .navigationTitle(date.jpMonthDayWeekday)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// メンバー表示順を名前順にそろえます。
    private var sortedMemberPlans: [MemberMealPlan] {
        memberPlans.sorted {
            $0.name.localizedCompare($1.name) == .orderedAscending
        }
    }

    /// 指定した食事時間の人数を返します。
    private func mealCount(for mealTime: MealTime) -> Int {
        memberPlans.filter { $0.status(for: mealTime) == .home }.count
    }

    /// データがまだない日の表示です。
    private var emptyStateCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(AppThemeColor.accent)

            Text("まだこの日の入力はありません")
                .font(.system(size: 16, weight: .semibold))

            Text("家族が朝・昼・夜を押すと、ここでまとめて確認できます。")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .background(
            LinearGradient(
                colors: [Color.white, AppThemeColor.secondaryCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppThemeColor.support.opacity(0.9), lineWidth: 1)
        )
    }

    /// この日を記録するためのボタンです。
    private var editButton: some View {
        Button {
            onOpenEditor()
        } label: {
            Label("この日を記録する", systemImage: "square.and.pencil")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppThemeColor.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

/// 1日分の必要食数を上部にまとめて表示するカードです。
private struct WeekDaySummaryCard: View {
    let breakfastCount: Int
    let lunchCount: Int
    let dinnerCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("この日のごはん")
                .font(.system(size: 18, weight: .semibold))

            HStack(spacing: 10) {
                summaryItem(title: MealTime.breakfast.rawValue, count: breakfastCount)
                summaryItem(title: MealTime.lunch.rawValue, count: lunchCount)
                summaryItem(title: MealTime.dinner.rawValue, count: dinnerCount)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.white, AppThemeColor.secondaryCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppThemeColor.support.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: AppThemeColor.accent.opacity(0.08), radius: 14, x: 0, y: 5)
    }

    /// 食数サマリーの1項目です。
    private func summaryItem(title: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Text("\(count)食")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppThemeColor.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(AppThemeColor.support.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// 1人分の食事状況を確認するカードです。
private struct WeekMemberStatusCard: View {
    let memberPlan: MemberMealPlan

    var body: some View {
        let trimmedNote = memberPlan.note.trimmingCharacters(in: .whitespacesAndNewlines)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(memberInitial)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppThemeColor.accent)
                    .frame(width: 38, height: 38)
                    .background(AppThemeColor.support)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(memberPlan.name)
                        .font(.system(size: 18, weight: .semibold))

                    Text("ごはんの記録")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppThemeColor.softText)
                }

                Spacer()
            }

            VStack(spacing: 10) {
                statusRow(mealTime: .breakfast, selectedStatus: memberPlan.breakfast)
                statusRow(mealTime: .lunch, selectedStatus: memberPlan.lunch)
                statusRow(mealTime: .dinner, selectedStatus: memberPlan.dinner)
            }

            if !trimmedNote.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("メモ")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppThemeColor.softText)

                    Text(trimmedNote)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(AppThemeColor.support.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.white, AppThemeColor.secondaryCard.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppThemeColor.support.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: AppThemeColor.accent.opacity(0.08), radius: 14, x: 0, y: 5)
    }

    private var memberInitial: String {
        let firstCharacter = memberPlan.name.trimmingCharacters(in: .whitespacesAndNewlines).first
        return firstCharacter.map { String($0) } ?? "?"
    }

    /// 今日タブと同じ並びで、朝昼夜それぞれの状態を表示します。
    private func statusRow(mealTime: MealTime, selectedStatus: MealStatus) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mealTitle(for: mealTime))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppThemeColor.softText)

            HStack(spacing: 8) {
                ForEach([MealStatus.undecided, .home, .out], id: \.self) { status in
                    statusOption(status: status, isSelected: selectedStatus == status)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 今日タブと同じ見た目で、選ばれている状態を表示します。
    private func statusOption(status: MealStatus, isSelected: Bool) -> some View {
        Text(status.inputLabel)
            .font(.system(size: 15, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? selectedFillColor(for: status) : Color.white.opacity(0.92))
            .foregroundStyle(isSelected ? status.textColor : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? status.borderColor : AppThemeColor.support, lineWidth: isSelected ? 2 : 1)
            )
    }

    /// 食事時間に応じた表示名を返します。
    private func mealTitle(for mealTime: MealTime) -> String {
        switch mealTime {
        case .breakfast:
            return "朝ごはん"
        case .lunch:
            return "昼ごはん"
        case .dinner:
            return "夜ごはん"
        }
    }

    /// 選択中の状態に合わせた背景色を返します。
    private func selectedFillColor(for status: MealStatus) -> Color {
        switch status {
        case .undecided:
            return AppThemeColor.peach.opacity(0.7)
        case .home:
            return AppThemeColor.mint.opacity(0.8)
        case .out:
            return AppThemeColor.lavender.opacity(0.8)
        }
    }
}

#Preview {
    NavigationStack {
        WeekScreenView(
            plans: [
                DayPlan(
                    date: Date(),
                    groupId: "A3FK9Q",
                    memberPlans: [
                        MemberMealPlan(memberId: "me", name: "れん", breakfast: .home, lunch: .out, dinner: .home, note: "夜は少し遅れます"),
                        MemberMealPlan(memberId: "family", name: "お母さん", breakfast: .home, lunch: .home, dinner: .undecided)
                    ]
                )
            ],
            onOpenEditorForDate: { _ in }
        )
    }
}
