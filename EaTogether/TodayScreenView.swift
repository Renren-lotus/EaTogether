//
//  TodayScreenView.swift
//  Original02
//
//  Created by Codex on 2026/05/27.
//

import SwiftUI

/// 今日の食事予定を表示する画面です。
struct TodayScreenView: View {
    let groupName: String
    let groupId: String
    let members: [GroupMember]
    let homeCountBreakfast: Int
    let homeCountLunch: Int
    let homeCountDinner: Int
    let statusProvider: (String, MealTime) -> MealStatus
    let noteProvider: (String) -> String
    let canEditMember: (String) -> Bool
    let onSelectStatus: (String, MealTime, MealStatus) -> Void
    let onOpenEditor: (String) -> Void

    var body: some View {
        let hasPendingMealInput = members
            .filter { canEditMember($0.id) }
            .contains { member in
                MealTime.allCases.contains { mealTime in
                    statusProvider(member.id, mealTime) == .undecided
                }
            }

        VStack(spacing: 0) {
            headerArea

            ScrollView {
                VStack(spacing: 14) {
                    if hasPendingMealInput {
                        PendingWarningView()
                    }

                    TodaySummaryCard(
                        breakfastCount: homeCountBreakfast,
                        lunchCount: homeCountLunch,
                        dinnerCount: homeCountDinner
                    )

                    ForEach(members) { member in
                        MemberMealCard(
                            member: member,
                            note: noteProvider(member.id),
                            isEditable: canEditMember(member.id),
                            statusProvider: { mealTime in
                                statusProvider(member.id, mealTime)
                            },
                            onSelectStatus: { mealTime, status in
                                onSelectStatus(member.id, mealTime, status)
                            },
                            onEdit: {
                                onOpenEditor(member.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
        }
        .background(AppThemeColor.baseBackground)
    }

    /// 画面上部のタイトル情報です。
    private var headerArea: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(Date().jpMonthDay)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)

            Text(groupName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppThemeColor.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppThemeColor.support)
                .clipShape(Capsule())

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 今日の必要食数を表示するサマリーカードです。
private struct TodaySummaryCard: View {
    let breakfastCount: Int
    let lunchCount: Int
    let dinnerCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日のごはん")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

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
        .shadow(color: AppThemeColor.accent.opacity(0.08), radius: 14, x: 0, y: 6)
    }

    /// サマリー1項目を表示します。
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
        .background(AppThemeColor.support.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// メンバー1人分の予定をカードで表示する部品です。
private struct MemberMealCard: View {
    let member: GroupMember
    let note: String
    let isEditable: Bool
    let statusProvider: (MealTime) -> MealStatus
    let onSelectStatus: (MealTime, MealStatus) -> Void
    let onEdit: () -> Void

    var body: some View {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(member.name)
                    .font(.system(size: 18, weight: .semibold))
                if member.isCurrentUser {
                    Text("あなた")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppThemeColor.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppThemeColor.mint.opacity(0.7))
                        .clipShape(Capsule())
                }

                Spacer()

                if isEditable {
                    Button {
                        onEdit()
                    } label: {
                        Label("メモを追加", systemImage: "pencil")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppThemeColor.accent)
                    }
                    .buttonStyle(.plain)
                } else {
                    Label("編集不可", systemImage: "lock")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 8) {
                ForEach(MealTime.allCases) { mealTime in
                    MealInputRow(
                        mealTime: mealTime,
                        selectedStatus: statusProvider(mealTime),
                        isEditable: isEditable,
                        onSelectStatus: { status in
                            onSelectStatus(mealTime, status)
                        }
                    )
                }
            }

            if !trimmedNote.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("メモ")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(trimmedNote)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
            }
        }
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
}

/// 未定の入力が残っていることをやさしく伝えるカードです。
private struct PendingWarningView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.orange.opacity(0.9))

            VStack(alignment: .leading, spacing: 4) {
                Text("まだ未定のごはんがあります")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("今日のごはん予定を入力してください")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor.peach.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

/// 朝昼夜ごとの入力行を表示する部品です。
private struct MealInputRow: View {
    let mealTime: MealTime
    let selectedStatus: MealStatus
    let isEditable: Bool
    let onSelectStatus: (MealStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mealTitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppThemeColor.softText)

            HStack(spacing: 8) {
                ForEach(MealStatus.allCases, id: \.self) { status in
                    MealStatusButton(
                        status: status,
                        isSelected: selectedStatus == status,
                        isEnabled: isEditable,
                        action: {
                            onSelectStatus(status)
                        }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mealTitle: String {
        switch mealTime {
        case .breakfast:
            return "朝ごはん"
        case .lunch:
            return "昼ごはん"
        case .dinner:
            return "夜ごはん"
        }
    }
}

/// 食事状態を大きめの選択ボタンで表示する部品です。
private struct MealStatusButton: View {
    let status: MealStatus
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(status.inputLabel)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(buttonBackgroundColor)
                .foregroundStyle(buttonTextColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(buttonBorderColor, lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.55)
    }

    private var buttonBackgroundColor: Color {
        if isSelected {
            return selectedFillColor
        }
        return Color.white.opacity(0.92)
    }

    private var buttonBorderColor: Color {
        if isSelected {
            return status.borderColor
        }
        return AppThemeColor.support
    }

    private var buttonTextColor: Color {
        if isSelected {
            return status.textColor
        }
        return .secondary
    }

    private var selectedFillColor: Color {
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
    let samplePlan = DayPlan(
        date: Date(),
        groupId: "A3FK9Q",
        memberPlans: [
            MemberMealPlan(memberId: "me", name: "自分", breakfast: .home, lunch: .out, dinner: .home, note: "19時ごろ帰宅します"),
            MemberMealPlan(memberId: "other", name: "父", breakfast: .home, lunch: .home, dinner: .out)
        ]
    )

    TodayScreenView(
        groupName: "わが家のごはん",
        groupId: "A3FK9Q",
        members: [
            GroupMember(id: "me", name: "自分", isCurrentUser: true),
            GroupMember(id: "other", name: "父", isCurrentUser: false)
        ],
        homeCountBreakfast: 2,
        homeCountLunch: 1,
        homeCountDinner: 1,
        statusProvider: { memberId, meal in
            samplePlan.memberPlans.first(where: { $0.memberId == memberId })?.status(for: meal) ?? .undecided
        },
        noteProvider: { memberId in
            samplePlan.memberPlans.first(where: { $0.memberId == memberId })?.note ?? ""
        },
        canEditMember: { $0 == "me" },
        onSelectStatus: { _, _, _ in },
        onOpenEditor: { _ in }
    )
}
