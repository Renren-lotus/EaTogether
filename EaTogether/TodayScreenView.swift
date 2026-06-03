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
    let members: [GroupMember]
    let homeCountBreakfast: Int
    let homeCountLunch: Int
    let homeCountDinner: Int
    let statusProvider: (String, MealTime) -> MealStatus
    let noteProvider: (String) -> String
    let canEditMember: (String) -> Bool
    let onCycleStatus: (String, MealTime) -> Void
    let onOpenEditor: (String) -> Void
    let onOpenGroupSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            headerArea

            ScrollView {
                VStack(spacing: 14) {
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
                            onCycleStatus: { mealTime in
                                onCycleStatus(member.id, mealTime)
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().jpMonthDay)
                    .font(.system(size: 20, weight: .semibold))
                Text(groupName)
                    .font(.system(size: 14))
                    .foregroundStyle(AppThemeColor.accent.opacity(0.8))
            }

            Spacer()

            Button {
                onOpenGroupSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(AppThemeColor.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

/// 今日の必要食数を表示するサマリーカードです。
private struct TodaySummaryCard: View {
    let breakfastCount: Int
    let lunchCount: Int
    let dinnerCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🍚 今日のごはん")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            HStack(spacing: 10) {
                summaryItem(title: MealTime.breakfast.rawValue, count: breakfastCount)
                summaryItem(title: MealTime.lunch.rawValue, count: lunchCount)
                summaryItem(title: MealTime.dinner.rawValue, count: dinnerCount)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppThemeColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppThemeColor.support.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    /// サマリー1項目を表示します。
    private func summaryItem(title: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text("\(count)食")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppThemeColor.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(AppThemeColor.support.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// メンバー1人分の予定をカードで表示する部品です。
private struct MemberMealCard: View {
    let member: GroupMember
    let note: String
    let isEditable: Bool
    let statusProvider: (MealTime) -> MealStatus
    let onCycleStatus: (MealTime) -> Void
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
                        .background(AppThemeColor.support.opacity(0.5))
                        .clipShape(Capsule())
                }

                Spacer()

                if isEditable {
                    Button {
                        onEdit()
                    } label: {
                        Label("予定を編集", systemImage: "pencil")
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
                    HStack {
                        Text("\(mealTime.rawValue)：")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .leading)

                        Button {
                            onCycleStatus(mealTime)
                        } label: {
                            MealStatusPill(status: statusProvider(mealTime))
                        }
                        .buttonStyle(.plain)
                        .disabled(!isEditable)
                        .opacity(isEditable ? 1.0 : 0.72)

                        Spacer()
                    }
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
        .padding(14)
        .background(AppThemeColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppThemeColor.support.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 7, x: 0, y: 2)
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
        onCycleStatus: { _, _ in },
        onOpenEditor: { _ in },
        onOpenGroupSettings: { }
    )
}
