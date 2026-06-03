//
//  EaTogetherApp.swift
//  EaTogether
//
//  Created by 坂下蓮 on 2026/06/03.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct EaTogetherApp: App {
    /// Firebaseの設定ファイルがあるときだけ初期設定します。
    init() {
        guard !AppRuntime.isPreview else { return }
        guard FirebaseApp.app() == nil else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return }
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: DayPlan.self)
    }
}
