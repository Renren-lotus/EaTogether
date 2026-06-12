//
//  MealCountWidget.swift
//  EaTogetherWidget
//
//  Created by Codex on 2026/06/07.
//

import SwiftUI
import WidgetKit

/// ウィジェットに渡す1回分の表示データです。
struct MealCountEntry: TimelineEntry {
    let date: Date
    let summary: TodayMealSummary
}

/// ウィジェットに表示する食数データを読み込みます。
struct MealCountProvider: TimelineProvider {
    private let store = TodayMealSummaryStore()

    func placeholder(in context: Context) -> MealCountEntry {
        MealCountEntry(date: Date(), summary: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (MealCountEntry) -> Void) {
        completion(MealCountEntry(date: Date(), summary: store.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MealCountEntry>) -> Void) {
        let entry = MealCountEntry(date: Date(), summary: store.load())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

/// 今日必要な食数だけを表示するウィジェットです。
struct MealCountWidgetEntryView: View {
    let entry: MealCountEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🍚 今日のごはん")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(entry.summary.groupName)
                .font(.caption)
                .foregroundStyle(accentColor)
                .lineLimit(1)

            HStack(spacing: 8) {
                countCard(title: "朝", count: entry.summary.breakfastCount)
                countCard(title: "昼", count: entry.summary.lunchCount)
                countCard(title: "夜", count: entry.summary.dinnerCount)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .containerBackground(backgroundColor, for: .widget)
    }

    /// 1食分の人数カードを表示します。
    private func countCard(title: String, count: Int) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(count)食")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(supportColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var accentColor: Color {
        Color(.sRGB, red: 74.0 / 255.0, green: 144.0 / 255.0, blue: 164.0 / 255.0, opacity: 1.0)
    }

    private var supportColor: Color {
        Color(.sRGB, red: 220.0 / 255.0, green: 238.0 / 255.0, blue: 239.0 / 255.0, opacity: 0.75)
    }

    private var backgroundColor: Color {
        Color(.sRGB, red: 245.0 / 255.0, green: 250.0 / 255.0, blue: 250.0 / 255.0, opacity: 1.0)
    }
}

/// EaTogetherの食数ウィジェットです。
@main
struct MealCountWidget: Widget {
    let kind = "MealCountWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MealCountProvider()) { entry in
            MealCountWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("今日のごはん")
        .description("今日必要な朝・昼・夜の食数を確認できます。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    MealCountWidget()
} timeline: {
    MealCountEntry(date: Date(), summary: .empty)
}
