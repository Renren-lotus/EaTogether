//
//  StartupSplashView.swift
//  EaTogether
//
//  Created by Codex on 2026/06/12.
//

import SwiftUI

/// アプリ起動時にやわらかく表示するスプラッシュ画面です。
struct StartupSplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppThemeColor.baseBackground, AppThemeColor.support.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                iconArtwork

                VStack(spacing: 8) {
                    Text("EaTogether")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppThemeColor.accent)

                    Text("今日のごはんを、やさしくひとつに。")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppThemeColor.softText)
                }
            }
            .padding(.horizontal, 32)
        }
    }

    /// 新しいアイコンと世界観をそろえた中央イラストです。
    private var iconArtwork: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.92))
                .frame(width: 168, height: 168)
                .shadow(color: AppThemeColor.accent.opacity(0.08), radius: 18, x: 0, y: 8)

            Circle()
                .trim(from: 0.12, to: 0.45)
                .stroke(AppThemeColor.peach.opacity(0.95), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 122, height: 122)
                .offset(x: -8, y: -8)

            Circle()
                .trim(from: 0.56, to: 0.88)
                .stroke(AppThemeColor.accent.opacity(0.9), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 122, height: 122)
                .offset(x: 8, y: -8)

            Circle()
                .fill(AppThemeColor.peach.opacity(0.95))
                .frame(width: 30, height: 30)
                .offset(x: 0, y: -54)

            Circle()
                .fill(AppThemeColor.accent.opacity(0.35))
                .frame(width: 28, height: 28)
                .offset(x: -52, y: 36)

            Circle()
                .fill(AppThemeColor.accent.opacity(0.6))
                .frame(width: 28, height: 28)
                .offset(x: 52, y: 36)

            Circle()
                .trim(from: 0.18, to: 0.82)
                .stroke(AppThemeColor.accent.opacity(0.45), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .frame(width: 104, height: 104)
                .offset(y: 12)

            BowlShape()
                .fill(
                    LinearGradient(
                        colors: [AppThemeColor.accent.opacity(0.6), AppThemeColor.accent.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 82, height: 60)
                .offset(y: 6)

            RiceShape()
                .fill(Color.white)
                .frame(width: 76, height: 44)
                .offset(y: -8)
        }
    }
}

/// お茶碗の形をやさしく描く部品です。
private struct BowlShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.25))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + rect.height * 0.25),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX + rect.width * 0.12, y: rect.maxY - rect.height * 0.08),
            control: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.1)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX - rect.width * 0.12, y: rect.maxY - rect.height * 0.08),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.25),
            control: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.1)
        )
        path.closeSubpath()
        return path
    }
}

/// ごはんのふくらみをやさしく描く部品です。
private struct RiceShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.maxY),
            control1: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.15),
            control2: CGPoint(x: rect.maxX - rect.width * 0.14, y: rect.minY + rect.height * 0.15)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.maxY),
            control1: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.maxY - rect.height * 0.02),
            control2: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY - rect.height * 0.02)
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    StartupSplashView()
}
