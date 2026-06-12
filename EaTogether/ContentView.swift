//
//  ContentView.swift
//  Original02
//
//  Created by 坂下蓮 on 2026/05/27.
//

import SwiftUI

/// アプリのホーム画面全体を表示するViewです。
struct ContentView: View {
    @State private var viewModel = MealPlannerViewModel()
    @State private var session = LocalGroupSession()
    @State private var inviteMessage = ""
    @State private var showingStartupSplash = true

    /// 画面の初期化を行います。
    init() { }

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        let todayPlan = viewModel.plan(for: Date(), groupId: session.groupId)
        let members = viewModel.members(
            groupId: session.groupId,
            currentUserId: session.currentUserId,
            currentUserName: session.currentUserName
        )
        let editingTargetPlan = viewModel.plan(for: viewModel.editingDate, groupId: session.groupId)
        let currentUserPlan = editingTargetPlan?.memberPlans.first(where: { $0.memberId == session.currentUserId })
        let todayBreakfastCount = viewModel.homeCount(for: .breakfast, in: todayPlan)
        let todayLunchCount = viewModel.homeCount(for: .lunch, in: todayPlan)
       let todayDinnerCount = viewModel.homeCount(for: .dinner, in: todayPlan)

        NavigationStack {
            VStack(spacing: 0) {
                if !viewModel.syncMessage.isEmpty {
                    Text(viewModel.syncMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.8))
                }

                HomeTabHeader(selectedPage: $bindableViewModel.selectedPage)
                    .onOpenGroupInvite {
                        viewModel.openGroupInvite()
                    }
                    .onOpenGroupSettings {
                        viewModel.openGroupSettings()
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                TabView(selection: $bindableViewModel.selectedPage) {
                    TodayScreenView(
                        groupName: session.displayGroupName,
                        groupId: session.groupId,
                        members: members,
                        homeCountBreakfast: todayBreakfastCount,
                        homeCountLunch: todayLunchCount,
                        homeCountDinner: todayDinnerCount,
                        statusProvider: { memberId, meal in
                            viewModel.status(for: memberId, mealTime: meal, in: todayPlan)
                        },
                        noteProvider: { memberId in
                            viewModel.note(for: memberId, in: todayPlan)
                        },
                        canEditMember: { memberId in
                            viewModel.canEdit(memberId: memberId, currentUserId: session.currentUserId)
                        },
                        onSelectStatus: { memberId, meal, status in
                            Task {
                                await viewModel.setStatus(
                                    status,
                                    for: memberId,
                                    mealTime: meal,
                                    date: Date(),
                                    groupId: session.groupId,
                                    currentUserId: session.currentUserId,
                                    currentUserName: session.currentUserName
                                )
                            }
                        },
                        onOpenEditor: { memberId in
                            let canEdit = viewModel.canEdit(memberId: memberId, currentUserId: session.currentUserId)
                            viewModel.openEditor(for: Date(), canEdit: canEdit)
                        }
                    )
                    .tag(HomePage.today)

                    WeekScreenView(
                        plans: viewModel.plans.filter { $0.groupId == session.groupId },
                        onOpenEditorForDate: { targetDate in
                            viewModel.openEditor(for: targetDate, canEdit: true)
                        }
                    )
                    .tag(HomePage.week)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.2), value: viewModel.selectedPage)
            }
            .background(AppThemeColor.baseBackground)
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $bindableViewModel.showingEditor) {
            MealEditorSheetView(
                targetDate: viewModel.editingDate,
                currentUserName: session.currentUserName,
                existingMemberPlan: currentUserPlan,
                onCancel: {
                    viewModel.closeEditor()
                },
                onSave: { breakfast, lunch, dinner, note in
                    Task {
                        await viewModel.saveOwnPlan(
                            for: viewModel.editingDate,
                            groupId: session.groupId,
                            currentUserId: session.currentUserId,
                            currentUserName: session.currentUserName,
                            breakfast: breakfast,
                            lunch: lunch,
                            dinner: dinner,
                            note: note
                        )
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $bindableViewModel.showingGroupSettings) {
            GroupSettingsSheetView(
                userName: session.currentUserName,
                groupName: session.displayGroupName,
                groupId: session.groupId,
                onUpdateUserName: { newName in
                    session.updateUserName(newName)
                },
                onUpdateGroupName: { newName in
                    session.updateGroupName(newName)
                },
                onClose: {
                    viewModel.closeGroupSettings()
                },
                onLeaveGroup: {
                    viewModel.closeGroupSettings()
                    session.clearGroup()
                    viewModel.stopRealtimeSync()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $bindableViewModel.showingGroupInvite) {
            ContentGroupInviteSheetView(
                groupName: session.displayGroupName,
                groupId: session.groupId,
                onClose: {
                    viewModel.closeGroupInvite()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { !session.isSetupCompleted },
                set: { _ in }
            )
        ) {
            GroupSetupView(
                initialInviteGroupId: session.pendingInviteGroupId,
                onCreateGroup: { userName, groupName in
                    session.createGroup(userName: userName, groupName: groupName)
                },
                onJoinGroup: { userName, groupId in
                    session.joinGroup(userName: userName, groupId: groupId)
                }
            )
            .id(session.pendingInviteGroupId)
        }
        .task(id: session.groupId) {
            await synchronizeCurrentGroup()
        }
        .onDisappear {
            viewModel.stopRealtimeSync()
        }
        .onOpenURL { url in
            handleInviteURL(url)
        }
        .alert("グループ招待", isPresented: Binding(
            get: { !inviteMessage.isEmpty },
            set: { isPresented in
                if !isPresented {
                    inviteMessage = ""
                }
            }
        )) {
            Button("OK") {
                inviteMessage = ""
            }
        } message: {
            Text(inviteMessage)
        }
        .overlay {
            if showingStartupSplash {
                StartupSplashView()
                    .transition(.opacity)
            }
        }
        .task {
            guard showingStartupSplash else { return }
            try? await Task.sleep(for: .milliseconds(1200))
            withAnimation(.easeOut(duration: 0.35)) {
                showingStartupSplash = false
            }
        }
    }

    /// Deep Linkの招待URLを受け取ってグループ参加へつなげます。
    private func handleInviteURL(_ url: URL) {
        guard let invitedGroupId = GroupInviteLink.groupId(from: url) else { return }
        viewModel.closeEditor()
        viewModel.closeGroupSettings()
        viewModel.stopRealtimeSync()
        session.joinGroupFromInvite(groupId: invitedGroupId)

        if session.isSetupCompleted {
            viewModel.selectedPage = .today
            inviteMessage = "グループ \(session.groupId) に参加しました。"
            Task {
                await synchronizeCurrentGroup()
            }
        } else {
            inviteMessage = "招待リンクを受け取りました。名前を入力して参加してください。"
        }
    }

    /// 現在のグループ情報をFirebaseへ登録して最新状態を取得します。
    private func synchronizeCurrentGroup() async {
        guard !AppRuntime.isPreview else { return }
        guard session.isSetupCompleted else { return }
        viewModel.startRealtimeSync(groupId: session.groupId)
        await viewModel.registerCurrentMember(
            groupId: session.groupId,
            currentUserId: session.currentUserId,
            currentUserName: session.currentUserName
        )
        await viewModel.refreshNow(groupId: session.groupId)
    }
}

/// 今日・今週タブを上部に表示するViewです。
private struct HomeTabHeader: View {
    @Binding var selectedPage: HomePage
    private var onOpenGroupInviteAction: (() -> Void)?
    private var onOpenGroupSettingsAction: (() -> Void)?

    init(selectedPage: Binding<HomePage>) {
        _selectedPage = selectedPage
        onOpenGroupInviteAction = nil
        onOpenGroupSettingsAction = nil
    }

    var body: some View {
        HStack(spacing: 12) {
            headerIconButton(systemName: "person.2", action: {
                onOpenGroupInviteAction?()
            })

            Spacer()

            HStack(spacing: 8) {
                ForEach(HomePage.allCases) { page in
                    Button {
                        selectedPage = page
                    } label: {
                        Text(page.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(selectedPage == page ? AppThemeColor.accent : AppThemeColor.softText)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selectedPage == page ? Color.white : Color.clear)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedPage == page ? AppThemeColor.support : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(AppThemeColor.support.opacity(0.85))
            .clipShape(Capsule())

            Spacer()

            headerIconButton(systemName: "gearshape", action: {
                onOpenGroupSettingsAction?()
            })
        }
    }

    /// 共有・設定用の丸いアイコンボタンです。
    private func headerIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppThemeColor.accent)
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AppThemeColor.support, lineWidth: 1)
                )
                .shadow(color: AppThemeColor.accent.opacity(0.12), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private extension HomeTabHeader {
    func onOpenGroupInvite(_ action: @escaping () -> Void) -> HomeTabHeader {
        var copy = self
        copy.onOpenGroupInviteAction = action
        return copy
    }

    func onOpenGroupSettings(_ action: @escaping () -> Void) -> HomeTabHeader {
        var copy = self
        copy.onOpenGroupSettingsAction = action
        return copy
    }
}

/// グループ招待用のQRコードと共有導線を表示するViewです。
private struct ContentGroupInviteSheetView: View {
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
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(AppThemeColor.baseBackground)
            .navigationTitle("グループに招待")
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
        }
    }

    /// 招待するグループの基本情報を表示します。
    private var inviteSummaryCard: some View {
        HStack(spacing: 14) {
            inviteHeroIllustration

            VStack(alignment: .leading, spacing: 10) {
                Text("Invite")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppThemeColor.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.82))
                    .clipShape(Capsule())

                Text(groupName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("グループID: \(groupId)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppThemeColor.softText)

                Text("下のQRコードを読み取るか、招待リンクをSNSで送ると、このグループに参加できます。")
                    .font(.system(size: 14))
                    .foregroundStyle(AppThemeColor.softText)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    /// QRコードと共有ボタンをまとめて表示します。
    private var qrCodeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("QRコード")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppThemeColor.softText)

            QRCodeImageView(text: inviteText)
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppThemeColor.support, lineWidth: 1)
                )

            ShareLink(item: inviteText) {
                Label("招待リンクを共有", systemImage: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppThemeColor.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            Text("LINEやInstagram、メールなどの共有先を選べます。")
                .font(.system(size: 13))
                .foregroundStyle(AppThemeColor.softText)

            inviteTips
        }
        .padding(18)
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
                .stroke(AppThemeColor.support, lineWidth: 1)
        )
        .shadow(color: AppThemeColor.accent.opacity(0.08), radius: 14, x: 0, y: 6)
    }

    private var inviteText: String {
        GroupInviteLink(groupId: groupId).url?.absoluteString ?? groupId
    }

    /// 招待画面の上部に置く小さなイラストです。
    private var inviteHeroIllustration: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: 74, height: 74)

            Circle()
                .trim(from: 0.08, to: 0.42)
                .stroke(AppThemeColor.peach.opacity(0.9), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 42, height: 42)
                .offset(x: -6, y: -6)

            Circle()
                .trim(from: 0.58, to: 0.92)
                .stroke(AppThemeColor.accent.opacity(0.9), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 42, height: 42)
                .offset(x: 7, y: -6)

            Image(systemName: "qrcode")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppThemeColor.accent)
        }
        .frame(width: 80, height: 80)
    }

    /// 招待方法をやさしく伝える補足です。
    private var inviteTips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("目の前ならQRコード", systemImage: "qrcode.viewfinder")
            Label("離れているならリンク共有", systemImage: "paperplane.fill")
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(AppThemeColor.softText)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor.support.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    ContentView()
}
