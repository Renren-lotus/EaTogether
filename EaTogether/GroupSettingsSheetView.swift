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
    let onUpdateGroupName: (String) -> Void
    let onClose: () -> Void
    let onLeaveGroup: () -> Void

    @State private var showLeaveAlert = false
    @State private var editableGroupName: String

    init(
        userName: String,
        groupName: String,
        groupId: String,
        onUpdateGroupName: @escaping (String) -> Void,
        onClose: @escaping () -> Void,
        onLeaveGroup: @escaping () -> Void
    ) {
        self.userName = userName
        self.groupId = groupId
        self.onUpdateGroupName = onUpdateGroupName
        self.onClose = onClose
        self.onLeaveGroup = onLeaveGroup
        _editableGroupName = State(initialValue: groupName)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                infoRow(title: "ユーザー名", value: userName)
                groupNameEditor
                infoRow(title: "グループID", value: groupId)

                Text("このグループIDを共有すると、同じグループとして使えます。")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    showLeaveAlert = true
                } label: {
                    Text("グループを変更する")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppThemeColor.support, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(AppThemeColor.baseBackground)
            .navigationTitle("グループ情報")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        onClose()
                    }
                    .foregroundStyle(AppThemeColor.accent)
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
        }
    }

    /// 情報行を表示します。
    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppThemeColor.support, lineWidth: 1)
                )
        }
    }

    /// グループ名を編集する行です。
    private var groupNameEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("グループ名")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField("グループ名", text: $editableGroupName)
                    .textFieldStyle(.roundedBorder)

                Button("保存") {
                    onUpdateGroupName(editableGroupName)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppThemeColor.accent)
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    GroupSettingsSheetView(
        userName: "れん",
        groupName: "わが家のごはん",
        groupId: "A3FK9Q",
        onUpdateGroupName: { _ in },
        onClose: { },
        onLeaveGroup: { }
    )
}
