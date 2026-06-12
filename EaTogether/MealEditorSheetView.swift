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
                Button {
                    onCancel()
                }
                label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppThemeColor.accent)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(spacing: 3) {
                    Text("ごはん予定を編集")
                        .font(.system(size: 17, weight: .semibold))
                    Text(targetDate.jpMonthDayWeekday)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppThemeColor.softText)
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
                            .foregroundStyle(AppThemeColor.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppThemeColor.support)
                            .clipShape(Capsule())
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    sectionCard(title: "ごはんの予定") {
                        MealEditSection(title: "朝ごはん", selection: $breakfast)
                        Divider()
                        MealEditSection(title: "昼ごはん", selection: $lunch)
                        Divider()
                        MealEditSection(title: "夜ごはん", selection: $dinner)
                    }

                    sectionCard(title: "ひとことメモ") {
                        ZStack(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("帰宅時間や連絡メモ")
                                    .font(.system(size: 16))
                                    .foregroundStyle(AppThemeColor.softText)
                                    .padding(.top, 8)
                                    .padding(.leading, 6)
                            }

                            TextEditor(text: $note)
                                .font(.system(size: 16))
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(AppThemeColor.support, lineWidth: 1)
                        )
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
                    .clipShape(RoundedRectangle(cornerRadius: 18))
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
                .foregroundStyle(AppThemeColor.softText)

            content()
        }
        .padding(18)
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
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppThemeColor.softText)

            HStack(spacing: 8) {
                statusButton(.home)
                statusButton(.out)
                statusButton(.undecided)
            }
        }
    }

    /// ステータス選択ボタンです。
    private func statusButton(_ status: MealStatus) -> some View {
        Button {
            selection = status
        } label: {
            Text(status.inputLabel)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(selection == status ? selectedFillColor(for: status) : Color.white.opacity(0.92))
                .foregroundStyle(selection == status ? status.textColor : .secondary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selection == status ? status.borderColor : AppThemeColor.support, lineWidth: selection == status ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
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
    MealEditorSheetView(
        targetDate: Date(),
        currentUserName: "れん",
        existingMemberPlan: nil,
        onCancel: { },
        onSave: { _, _, _, _ in }
    )
}
