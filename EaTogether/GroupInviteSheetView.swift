//
//  GroupInviteSheetView.swift
//  EaTogether
//
//  Created by Codex on 2026/06/12.
//

import SwiftUI

/// グループ招待用のQRコードと共有導線を表示する画面です。
struct GroupInviteSheetView: View {
    let groupName: String
    let groupId: String
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    inviteSummaryCard
                    qrCodeCard
                }
                .padding(20)
            }
            .background(AppThemeColor.baseBackground)
            .navigationTitle("グループに招待")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        onClose()
                    }
                    .foregroundStyle(AppThemeColor.accent)
                }
            }
        }
    }

    /// 招待先のグループ情報を表示します。
    private var inviteSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(groupName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)

            Text("グループID: \(groupId)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            Text("下のQRコードを読み取るか、招待リンクをSNSで送ると、このグループに参加できます。")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor.support, lineWidth: 1)
        )
    }

    /// QRコードと共有ボタンを表示します。
    private var qrCodeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("QRコード")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)

            QRCodeImageView(text: inviteText)
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppThemeColor.support, lineWidth: 1)
                )

            ShareLink(item: inviteText) {
                Label("招待リンクを共有", systemImage: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppThemeColor.support.opacity(0.55))
                    .foregroundStyle(AppThemeColor.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Text("LINEやInstagram、メールなどの共有先を選べます。")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }

    private var inviteText: String {
        GroupInviteLink(groupId: groupId).url?.absoluteString ?? groupId
    }
}

#Preview {
    GroupInviteSheetView(
        groupName: "わが家のごはん",
        groupId: "A3FK9Q",
        onClose: { }
    )
}
