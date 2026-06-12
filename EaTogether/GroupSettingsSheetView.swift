//
//  GroupSettingsSheetView.swift
//  Original02
//
//  Created by Codex on 2026/05/29.
//

import SwiftUI

/// 現在のグループ情報を確認する設定画面です。
struct GroupSettingsSheetView: View {
    let userName: String
    let groupId: String
    let onUpdateUserName: (String) -> Void
    let onUpdateGroupName: (String) -> Void
    let onClose: () -> Void
    let onLeaveGroup: () -> Void

    @State private var showLeaveAlert = false
    @State private var editableUserName: String
    @State private var editableGroupName: String
    @State private var reminderManager = MealReminderManager()

    init(
        userName: String,
        groupName: String,
        groupId: String,
        onUpdateUserName: @escaping (String) -> Void,
        onUpdateGroupName: @escaping (String) -> Void,
        onClose: @escaping () -> Void,
        onLeaveGroup: @escaping () -> Void
    ) {
        self.userName = userName
        self.groupId = groupId
        self.onUpdateUserName = onUpdateUserName
        self.onUpdateGroupName = onUpdateGroupName
        self.onClose = onClose
        self.onLeaveGroup = onLeaveGroup
        _editableUserName = State(initialValue: userName)
        _editableGroupName = State(initialValue: groupName)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    settingsHeroCard
                    userNameEditor
                    groupNameEditor
                    infoRow(title: "グループID", value: groupId)
                    reminderEditor
                    leaveGroupButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(AppThemeColor.baseBackground)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onClose()
                    }
                    label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppThemeColor.accent)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
            }
            .alert("グループを変更しますか？", isPresented: $showLeaveAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("変更する", role: .destructive) {
                    onLeaveGroup()
                }
            } message: {
                Text("現在のグループから離れて、グループ設定画面に戻ります。")
            }
            .task {
                await reminderManager.refreshAuthorizationStatus()
            }
        }
    }

    /// 設定画面の雰囲気を伝える上部カードです。
    private var settingsHeroCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppThemeColor.support)
                    .frame(width: 58, height: 58)

                Image(systemName: "person.2.crop.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppThemeColor.accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Settings")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppThemeColor.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Capsule())

                Text("いつもの設定をまとめて管理")
                    .font(.system(size: 19, weight: .semibold))

                Text("名前やグループ情報、通知の時間をここで整えられます。")
                    .font(.system(size: 13))
                    .foregroundStyle(AppThemeColor.softText)
            }

            Spacer()
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [AppThemeColor.support.opacity(0.9), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppThemeColor.support, lineWidth: 1)
        )
        .shadow(color: AppThemeColor.accent.opacity(0.08), radius: 14, x: 0, y: 6)
    }

    /// グループ変更ボタンを表示します。
    private var leaveGroupButton: some View {
        Button {
            showLeaveAlert = true
        } label: {
            Text("グループを変更する")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppThemeColor.peach.opacity(0.55))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppThemeColor.support, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    /// 情報行を表示します。
    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppThemeColor.softText)
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [Color.white, AppThemeColor.secondaryCard],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppThemeColor.support, lineWidth: 1)
                )
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.white, AppThemeColor.secondaryCard.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppThemeColor.support, lineWidth: 1)
        )
        .shadow(color: AppThemeColor.accent.opacity(0.08), radius: 14, x: 0, y: 6)
    }

    /// ユーザー名を編集する行です。
    private var userNameEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("自分の名前", systemImage: "person.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppThemeColor.softText)

            HStack(spacing: 8) {
                TextField("自分の名前", text: $editableUserName)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppThemeColor.support, lineWidth: 1)
                    )

                Button("保存") {
                    onUpdateUserName(editableUserName)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppThemeColor.accent)
                .clipShape(Capsule())
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.white, AppThemeColor.secondaryCard.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppThemeColor.support, lineWidth: 1)
        )
        .shadow(color: AppThemeColor.accent.opacity(0.08), radius: 14, x: 0, y: 6)
    }

    /// グループ名を編集する行です。
    private var groupNameEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("グループ名", systemImage: "person.3.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppThemeColor.softText)

            HStack(spacing: 8) {
                TextField("グループ名", text: $editableGroupName)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppThemeColor.support, lineWidth: 1)
                    )

                Button("保存") {
                    onUpdateGroupName(editableGroupName)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppThemeColor.accent)
                .clipShape(Capsule())
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.white, AppThemeColor.secondaryCard.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppThemeColor.support, lineWidth: 1)
        )
        .shadow(color: AppThemeColor.accent.opacity(0.08), radius: 14, x: 0, y: 6)
    }

    /// 記録忘れ防止通知を設定するカードです。
    private var reminderEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("記録忘れ通知")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppThemeColor.softText)

            Toggle(
                "毎日通知する",
                isOn: Binding(
                    get: { reminderManager.isReminderEnabled },
                    set: { isEnabled in
                        Task {
                            await reminderManager.setReminderEnabled(isEnabled)
                        }
                    }
                )
            )
            .font(.system(size: 16, weight: .semibold))

            DatePicker(
                "通知時間",
                selection: Binding(
                    get: { reminderManager.reminderTime },
                    set: { time in
                        Task {
                            await reminderManager.setReminderTime(time)
                        }
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .disabled(!reminderManager.isReminderEnabled)
            .opacity(reminderManager.isReminderEnabled ? 1.0 : 0.45)

            Text("設定した時間に毎日「ご飯の予定が未定です！」と通知します。")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            if !reminderManager.statusMessage.isEmpty {
                Text(reminderManager.statusMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppThemeColor.accent)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.white, AppThemeColor.secondaryCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppThemeColor.support, lineWidth: 1)
        )
        .shadow(color: AppThemeColor.accent.opacity(0.08), radius: 14, x: 0, y: 6)
    }
}

#Preview {
    GroupSettingsSheetView(
        userName: "れん",
        groupName: "わが家のごはん",
        groupId: "A3FK9Q",
        onUpdateUserName: { _ in },
        onUpdateGroupName: { _ in },
        onClose: { },
        onLeaveGroup: { }
    )
}
