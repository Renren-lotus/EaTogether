//
//  GroupSetupView.swift
//  Original02
//
//  Created by Codex on 2026/05/29.
//

import SwiftUI

/// グループ作成・参加を行う初期設定画面です。
struct GroupSetupView: View {
    let onCreateGroup: (String, String) -> Void
    let onJoinGroup: (String, String) -> Void

    @State private var mode: SetupMode = .create
    @State private var userName = ""
    @State private var inputGroupName = ""
    @State private var inputGroupId = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("設定モード", selection: $mode) {
                    ForEach(SetupMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    Text("あなたの名前")
                        .font(.system(size: 14, weight: .medium))
                    TextField("例: 太郎", text: $userName)
                        .textFieldStyle(.roundedBorder)
                }

                if mode == .create {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("グループ名（表示名）")
                            .font(.system(size: 14, weight: .medium))
                        TextField("例: 田中家", text: $inputGroupName)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                if mode == .join {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("グループID")
                            .font(.system(size: 14, weight: .medium))
                        TextField("例: A3FK9Q", text: $inputGroupId)
                            .textInputAutocapitalization(.characters)
                            .textFieldStyle(.roundedBorder)
                    }
                } else {
                    Text("作成すると6文字のグループIDが発行されます。")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                Button {
                    if mode == .create {
                        onCreateGroup(trimmedUserName, trimmedGroupName)
                    } else {
                        onJoinGroup(trimmedUserName, trimmedGroupId)
                    }
                } label: {
                    Text(mode.primaryButtonTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppThemeColor.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1.0 : 0.5)
            }
            .padding(20)
            .background(AppThemeColor.baseBackground)
            .navigationTitle("グループ設定")
        }
    }

    /// 入力値を送信可能か判定します。
    private var canSubmit: Bool {
        if trimmedUserName.isEmpty {
            return false
        }
        if mode == .join {
            return !trimmedGroupId.isEmpty
        }
        return !trimmedGroupName.isEmpty
    }

    private var trimmedUserName: String {
        userName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedGroupId: String {
        inputGroupId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private var trimmedGroupName: String {
        inputGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// 初期設定画面のモードです。
private enum SetupMode: String, CaseIterable, Identifiable {
    case create
    case join

    var id: String { rawValue }

    var title: String {
        switch self {
        case .create:
            return "新規作成"
        case .join:
            return "参加"
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .create:
            return "グループを作成"
        case .join:
            return "グループに参加"
        }
    }
}

#Preview {
    GroupSetupView(
        onCreateGroup: { _, _ in },
        onJoinGroup: { _, _ in }
    )
}
