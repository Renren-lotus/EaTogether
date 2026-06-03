//
//  MealStatusCircleView.swift
//  Original02
//
//  Created by Codex on 2026/05/27.
//

import SwiftUI

/// 食事の状態をラベル付きピルで表示する共通部品です。
struct MealStatusCircle: View {
    let status: MealStatus

    var body: some View {
        MealStatusPill(status: status, isCompact: true)
    }
}

/// 食事状態をわかりやすいチップ形式で表示する部品です。
struct MealStatusPill: View {
    let status: MealStatus
    var isCompact = false

    var body: some View {
        Text(status.displayLabel)
            .font(.system(size: isCompact ? 13 : 14, weight: .semibold))
            .foregroundStyle(status.textColor)
            .lineLimit(1)
            .padding(.horizontal, isCompact ? 10 : 12)
            .padding(.vertical, isCompact ? 6 : 8)
            .background(
                Capsule()
                    .fill(status.backgroundColor)
            )
            .overlay(
                Capsule()
                    .strokeBorder(status.borderColor, lineWidth: 1)
            )
    }
}

/// MealStatusに表示用スタイルを追加します。
private extension MealStatus {
    var displayLabel: String {
        switch self {
        case .undecided:
            return "？ 未定"
        case .home:
            return "🍚 いる"
        case .out:
            return "🚶 外食"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .undecided:
            return Color.yellow.opacity(0.16)
        case .home:
            return Color.green.opacity(0.18)
        case .out:
            return Color.gray.opacity(0.16)
        }
    }

    var borderColor: Color {
        switch self {
        case .undecided:
            return Color.yellow.opacity(0.45)
        case .home:
            return Color.green.opacity(0.45)
        case .out:
            return Color.gray.opacity(0.4)
        }
    }

    var textColor: Color {
        switch self {
        case .undecided:
            return Color.orange.opacity(0.9)
        case .home:
            return Color.green.opacity(0.95)
        case .out:
            return Color.gray.opacity(0.9)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            MealStatusCircle(status: .undecided)
            MealStatusCircle(status: .home)
            MealStatusCircle(status: .out)
        }

        HStack(spacing: 12) {
            MealStatusPill(status: .undecided)
            MealStatusPill(status: .home)
            MealStatusPill(status: .out)
        }
    }
    .padding()
    .background(AppThemeColor.baseBackground)
}
