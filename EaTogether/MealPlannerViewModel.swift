//
//  MealPlannerViewModel.swift
//  Original02
//
//  Created by Codex on 2026/05/27.
//

import Foundation
import Observation

/// 上部タブのページ種類です。
enum HomePage: Int, CaseIterable, Identifiable {
    case today
    case week

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .today:
            return "今日"
        case .week:
            return "今週"
        }
    }
}

/// グループ内の表示用メンバー情報です。
struct GroupMember: Identifiable, Hashable {
    var id: String
    var name: String
    var isCurrentUser: Bool
}

/// 食事予定画面全体の状態と処理を管理します。
@Observable
final class MealPlannerViewModel {
    var selectedPage: HomePage = .today
    var showingEditor = false
    var showingGroupSettings = false
    var showingGroupInvite = false
    var editingDate = Date()
    var plans: [DayPlan] = []
    var groupMembers: [GroupMemberEntry] = []
    var isSyncing = false
    var syncMessage = ""

    private let syncService = GroupRealtimeSyncService()
    private var syncTask: Task<Void, Never>?
    private var syncingGroupId = ""
    private var syncToken = UUID()

    /// 編集モーダルを開きます。
    func openEditor(for date: Date, canEdit: Bool) {
        guard canEdit else { return }
        editingDate = date
        showingEditor = true
    }

    /// 編集モーダルを閉じます。
    func closeEditor() {
        showingEditor = false
    }

    /// グループ設定モーダルを開きます。
    func openGroupSettings() {
        showingGroupSettings = true
    }

    /// グループ設定モーダルを閉じます。
    func closeGroupSettings() {
        showingGroupSettings = false
    }

    /// グループ共有モーダルを開きます。
    func openGroupInvite() {
        showingGroupInvite = true
    }

    /// グループ共有モーダルを閉じます。
    func closeGroupInvite() {
        showingGroupInvite = false
    }

    /// リアルタイム同期を開始します。
    func startRealtimeSync(groupId: String) {
        guard !AppRuntime.isPreview else {
            stopRealtimeSync()
            syncMessage = ""
            return
        }

        let normalized = groupId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else {
            stopRealtimeSync()
            plans = []
            groupMembers = []
            syncMessage = ""
            return
        }

        if syncingGroupId == normalized, syncTask != nil {
            return
        }

        stopRealtimeSync()
        syncingGroupId = normalized
        syncToken = UUID()
        let token = syncToken

        syncTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshGroup(groupId: normalized, token: token)

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                if Task.isCancelled { break }
                await self.refreshGroup(groupId: normalized, token: token)
            }
        }
    }

    /// リアルタイム同期を停止します。
    func stopRealtimeSync() {
        syncTask?.cancel()
        syncTask = nil
        syncingGroupId = ""
        isSyncing = false
    }

    /// 指定グループの予定を即時再取得します。
    func refreshNow(groupId: String) async {
        await refreshGroup(groupId: groupId, token: syncToken)
    }

    /// 指定日付のデータを一覧から取得します。
    func plan(for date: Date, groupId: String) -> DayPlan? {
        let key = DayPlan.groupDayKey(groupId: groupId, date: date)
        return plans.first(where: { $0.groupDayKey == key })
    }

    /// グループ内の表示メンバー一覧を返します。
    func members(groupId: String, currentUserId: String, currentUserName: String) -> [GroupMember] {
        var map: [String: String] = [currentUserId: currentUserName]

        let syncedMembers = groupMembers.filter { $0.groupId == groupId }
        for member in syncedMembers {
            map[member.memberId] = member.memberName
        }

        let groupedPlans = plans.filter { $0.groupId == groupId }
        for dayPlan in groupedPlans {
            for memberPlan in dayPlan.memberPlans {
                map[memberPlan.memberId] = memberPlan.name
            }
        }

        return map
            .map { key, value in
                GroupMember(id: key, name: value, isCurrentUser: key == currentUserId)
            }
            .sorted {
                if $0.isCurrentUser != $1.isCurrentUser {
                    return $0.isCurrentUser
                }
                return $0.name.localizedCompare($1.name) == .orderedAscending
            }
    }

    /// 現在のユーザーをグループ参加メンバーとして登録します。
    func registerCurrentMember(groupId: String, currentUserId: String, currentUserName: String) async {
        rememberLocalMember(groupId: groupId, memberId: currentUserId, memberName: currentUserName)

        var lastError: Error?
        do {
            try await syncService.upsertMember(
                groupId: groupId,
                memberId: currentUserId,
                memberName: currentUserName
            )
        } catch {
            lastError = error
        }

        do {
            try await syncService.ensureTodayMemberEntry(
                groupId: groupId,
                memberId: currentUserId,
                memberName: currentUserName,
                date: Date()
            )
            syncMessage = ""
        } catch {
            syncMessage = syncFailureMessage(from: error)
            return
        }

        if let lastError {
            syncMessage = memberSyncFailureMessage(from: lastError)
        }
    }

    /// メンバーの編集可否を判定します。
    func canEdit(memberId: String, currentUserId: String) -> Bool {
        memberId == currentUserId
    }

    /// 家族1人分の食事状態を順番に切り替えます。
    func cycleStatus(
        for memberId: String,
        mealTime: MealTime,
        date: Date,
        groupId: String,
        currentUserId: String,
        currentUserName: String
    ) async {
        guard canEdit(memberId: memberId, currentUserId: currentUserId) else { return }

        let targetPlan = ensurePlan(for: date, groupId: groupId, currentUserId: currentUserId, currentUserName: currentUserName)
        var targetMember = targetPlan.memberPlans.first(where: { $0.memberId == currentUserId })
            ?? MemberMealPlan(memberId: currentUserId, name: currentUserName)

        let current = targetMember.status(for: mealTime)
        targetMember.setStatus(current.next(), for: mealTime)
        targetMember.name = currentUserName
        replaceMemberPlan(targetMember, on: targetPlan)
        refreshLocalPlansOrder()

        let entry = GroupMealEntry(
            groupId: groupId,
            dayKey: targetPlan.dayKey,
            date: targetPlan.date,
            memberId: targetMember.memberId,
            memberName: targetMember.name,
            breakfast: targetMember.breakfast,
            lunch: targetMember.lunch,
            dinner: targetMember.dinner,
            note: targetMember.note
        )

        do {
            try await syncService.upsert(entry: entry)
            await registerCurrentMember(
                groupId: groupId,
                currentUserId: targetMember.memberId,
                currentUserName: targetMember.name
            )
        } catch {
            syncMessage = syncFailureMessage(from: error)
        }
    }

    /// 家族1人分の食事状態を指定した内容へ更新します。
    func setStatus(
        _ status: MealStatus,
        for memberId: String,
        mealTime: MealTime,
        date: Date,
        groupId: String,
        currentUserId: String,
        currentUserName: String
    ) async {
        guard canEdit(memberId: memberId, currentUserId: currentUserId) else { return }

        let targetPlan = ensurePlan(for: date, groupId: groupId, currentUserId: currentUserId, currentUserName: currentUserName)
        var targetMember = targetPlan.memberPlans.first(where: { $0.memberId == currentUserId })
            ?? MemberMealPlan(memberId: currentUserId, name: currentUserName)

        targetMember.setStatus(status, for: mealTime)
        targetMember.name = currentUserName
        replaceMemberPlan(targetMember, on: targetPlan)
        refreshLocalPlansOrder()

        let entry = GroupMealEntry(
            groupId: groupId,
            dayKey: targetPlan.dayKey,
            date: targetPlan.date,
            memberId: targetMember.memberId,
            memberName: targetMember.name,
            breakfast: targetMember.breakfast,
            lunch: targetMember.lunch,
            dinner: targetMember.dinner,
            note: targetMember.note
        )

        do {
            try await syncService.upsert(entry: entry)
            await registerCurrentMember(
                groupId: groupId,
                currentUserId: targetMember.memberId,
                currentUserName: targetMember.name
            )
        } catch {
            syncMessage = syncFailureMessage(from: error)
        }
    }

    /// 編集画面の保存内容を反映します。
    func saveOwnPlan(
        for date: Date,
        groupId: String,
        currentUserId: String,
        currentUserName: String,
        breakfast: MealStatus,
        lunch: MealStatus,
        dinner: MealStatus,
        note: String
    ) async {
        let targetPlan = ensurePlan(for: date, groupId: groupId, currentUserId: currentUserId, currentUserName: currentUserName)

        let member = MemberMealPlan(
            memberId: currentUserId,
            name: currentUserName,
            breakfast: breakfast,
            lunch: lunch,
            dinner: dinner,
            note: note
        )
        replaceMemberPlan(member, on: targetPlan)
        refreshLocalPlansOrder()
        closeEditor()

        let entry = GroupMealEntry(
            groupId: groupId,
            dayKey: targetPlan.dayKey,
            date: targetPlan.date,
            memberId: member.memberId,
            memberName: member.name,
            breakfast: member.breakfast,
            lunch: member.lunch,
            dinner: member.dinner,
            note: member.note
        )

        do {
            try await syncService.upsert(entry: entry)
            await registerCurrentMember(
                groupId: groupId,
                currentUserId: member.memberId,
                currentUserName: member.name
            )
        } catch {
            syncMessage = syncFailureMessage(from: error)
        }
    }

    /// 指定時間帯で「家で食べる」人数を返します。
    func homeCount(for mealTime: MealTime, in plan: DayPlan?) -> Int {
        guard let plan else { return 0 }
        return plan.memberPlans.filter { $0.status(for: mealTime) == .home }.count
    }

    /// 指定メンバーの食事状態を返します。
    func status(for memberId: String, mealTime: MealTime, in plan: DayPlan?) -> MealStatus {
        guard let plan else { return .undecided }
        guard let target = plan.memberPlans.first(where: { $0.memberId == memberId }) else {
            return .undecided
        }
        return target.status(for: mealTime)
    }

    /// 指定メンバーのメモを返します。
    func note(for memberId: String, in plan: DayPlan?) -> String {
        guard let plan else { return "" }
        guard let target = plan.memberPlans.first(where: { $0.memberId == memberId }) else {
            return ""
        }
        return target.note
    }

    /// 表示用の1週間の日付キーを作ります。
    private func weekDayKeys() -> [String] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return DayPlan.dayKey(from: date)
        }
    }

    /// 指定グループのデータを取得して反映します。
    @MainActor
    private func refreshGroup(groupId: String, token: UUID) async {
        guard token == syncToken else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            let keys = weekDayKeys()
            let resolvedEntries = try await syncService.fetchEntries(groupId: groupId, dayKeys: keys)
            let resolvedMembers = await fetchMembersWithoutBlockingEntries(groupId: groupId)
            guard token == syncToken else { return }
            plans = Self.buildPlans(from: resolvedEntries)
            groupMembers = resolvedMembers
        } catch {
            guard token == syncToken else { return }
            syncMessage = syncFailureMessage(from: error)
        }
    }

    /// 同期エラーを画面に出す短い文章へ変換します。
    private func syncFailureMessage(from error: Error) -> String {
        let detail = error.localizedDescription
        if isFirestorePermissionError(detail) {
            return "同期に失敗しました。FirebaseのFirestoreルールを確認してください。"
        }
        guard !detail.isEmpty else {
            return "同期に失敗しました。Firebase設定を確認してください。"
        }
        return "同期に失敗しました: \(detail)"
    }

    /// メンバー一覧だけを取得し、失敗しても食事予定の同期は止めません。
    private func fetchMembersWithoutBlockingEntries(groupId: String) async -> [GroupMemberEntry] {
        do {
            let members = try await syncService.fetchMembers(groupId: groupId)
            return members
        } catch {
            if syncMessage.isEmpty {
                syncMessage = memberSyncFailureMessage(from: error)
            }
            return groupMembers
        }
    }

    /// 画面上ではすぐにメンバーが見えるよう、ローカルにもメンバーを記録します。
    private func rememberLocalMember(groupId: String, memberId: String, memberName: String) {
        let trimmedName = memberName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !groupId.isEmpty, !memberId.isEmpty, !trimmedName.isEmpty else { return }

        let entry = GroupMemberEntry(
            groupId: groupId,
            memberId: memberId,
            memberName: trimmedName,
            updatedAt: Date()
        )

        if let index = groupMembers.firstIndex(where: { $0.groupId == groupId && $0.memberId == memberId }) {
            groupMembers[index] = entry
        } else {
            groupMembers.append(entry)
        }
    }

    /// メンバー同期エラーを画面に出す短い文章へ変換します。
    private func memberSyncFailureMessage(from error: Error) -> String {
        let detail = error.localizedDescription
        if isFirestorePermissionError(detail) {
            return "メンバー同期に失敗しました。FirebaseのgroupMembersルールを確認してください。"
        }
        guard !detail.isEmpty else {
            return "メンバー同期に失敗しました。Firebase設定を確認してください。"
        }
        return "メンバー同期に失敗しました: \(detail)"
    }

    /// Firestoreの権限エラーかどうかを判定します。
    private func isFirestorePermissionError(_ message: String) -> Bool {
        message.localizedCaseInsensitiveContains("permission")
            || message.localizedCaseInsensitiveContains("insufficient")
    }

    /// Entry配列を日付単位の予定配列に変換します。
    private static func buildPlans(from entries: [GroupMealEntry]) -> [DayPlan] {
        let grouped = Dictionary(grouping: entries) { entry in
            DayPlan.groupDayKey(groupId: entry.groupId, date: entry.date)
        }

        return grouped.values.compactMap { groupEntries in
            guard let first = groupEntries.first else { return nil }
            let members = groupEntries.map { entry in
                MemberMealPlan(
                    memberId: entry.memberId,
                    name: entry.memberName,
                    breakfast: entry.breakfast,
                    lunch: entry.lunch,
                    dinner: entry.dinner,
                    note: entry.note
                )
            }

            return DayPlan(date: first.date, groupId: first.groupId, memberPlans: members)
        }
        .sorted { $0.date < $1.date }
    }

    /// 指定日の予定を必ず返し、無ければローカルで初期作成します。
    private func ensurePlan(for date: Date, groupId: String, currentUserId: String, currentUserName: String) -> DayPlan {
        if let existing = plan(for: date, groupId: groupId) {
            return existing
        }

        let newPlan = DayPlan(
            date: date,
            groupId: groupId,
            memberPlans: [MemberMealPlan(memberId: currentUserId, name: currentUserName)]
        )
        plans.append(newPlan)
        plans.sort { $0.date < $1.date }
        return newPlan
    }

    /// 指定プランにメンバーデータを反映します。
    private func replaceMemberPlan(_ memberPlan: MemberMealPlan, on dayPlan: DayPlan) {
        if let index = dayPlan.memberPlans.firstIndex(where: { $0.memberId == memberPlan.memberId }) {
            dayPlan.memberPlans[index] = memberPlan
        } else {
            dayPlan.memberPlans.append(memberPlan)
        }
    }

    /// ローカル配列を再代入してUIに変更を通知します。
    private func refreshLocalPlansOrder() {
        plans = plans.sorted { $0.date < $1.date }
    }
}
