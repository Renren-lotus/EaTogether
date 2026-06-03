//
//  MealEditorSheetView.swift
//  Original02
//
//  Created by Codex on 2026/05/27.
//

import SwiftUI

/// 食事予定を入力するモーダル画面です。
struct MealEditorSheetView: View {
    let targetDate: Date
    let currentUserName: String
    let existingMemberPlan: MemberMealPlan?
    let onCancel: () -> Void
    let onSave: (MealStatus, MealStatus, MealStatus, String) -> Void

    @State private var breakfast: MealStatus = .undecided
    @State private var lunch: MealStatus = .undecided
    @State private var dinner: MealStatus = .undecided
    @State private var note: String = ""
    @State private var hasInitialized = false
    @State private var saveFeedbackTrigger = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("閉じる") {
                    onCancel()
                }
                .foregroundStyle(AppThemeColor.accent)

                Spacer()

                VStack(spacing: 3) {
                    Text("ごはん予定を編集")
                        .font(.system(size: 17, weight: .semibold))
                    Text(targetDate.jpMonthDayWeekday)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Color.clear
                    .frame(width: 40, height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            ScrollView {
                VStack(spacing: 14) {
                    sectionCard(title: "入力者") {
                        Text(currentUserName)
                            .font(.system(size: 18, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    sectionCard(title: "今日のごはん") {
                        MealEditSection(title: MealTime.breakfast.rawValue, selection: $breakfast)
                        Divider()
                        MealEditSection(title: MealTime.lunch.rawValue, selection: $lunch)
                        Divider()
                        MealEditSection(title: MealTime.dinner.rawValue, selection: $dinner)
                    }

                    sectionCard(title: "ひとことメモ") {
                        ZStack(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("帰宅時間や連絡メモ")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 6)
                            }

                            TextEditor(text: $note)
                                .font(.system(size: 16))
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
            .background(AppThemeColor.baseBackground)

            Button {
                saveFeedbackTrigger += 1
                onSave(breakfast, lunch, dinner, note)
            } label: {
                Text("予定を保存")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppThemeColor.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 22)
            .background(AppThemeColor.baseBackground)
        }
        .sensoryFeedback(.success, trigger: saveFeedbackTrigger)
        .background(AppThemeColor.baseBackground)
        .onAppear {
            guard !hasInitialized else { return }
            setupInitialState()
            hasInitialized = true
        }
    }

    /// セクション見出し付きのカードです。
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            content()
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
    }

    /// 初回表示時の状態を設定します。
    private func setupInitialState() {
        guard let existingMemberPlan else { return }
        breakfast = existingMemberPlan.breakfast
        lunch = existingMemberPlan.lunch
        dinner = existingMemberPlan.dinner
        note = existingMemberPlan.note
    }
}

/// 朝昼夜の入力行です。
private struct MealEditSection: View {
    let title: String
    @Binding var selection: MealStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)

            HStack(spacing: 10) {
                statusButton(.undecided)
                statusButton(.home)
                statusButton(.out)
            }
        }
    }

    /// ステータス選択ボタンです。
    private func statusButton(_ status: MealStatus) -> some View {
        Button {
            selection = status
        } label: {
            MealStatusPill(status: status)
                .opacity(selection == status ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MealEditorSheetView(
        targetDate: Date(),
        currentUserName: "れん",
        existingMemberPlan: nil,
        onCancel: { },
        onSave: { _, _, _, _ in }
    )
}
