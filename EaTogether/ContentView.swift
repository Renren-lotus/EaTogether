//
//  ContentView.swift
//  Original02
//
//  Created by 坂下蓮 on 2026/05/27.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

/// アプリのホーム画面全体を表示するViewです。
struct ContentView: View {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State private var viewModel = MealPlannerViewModel()
    @State private var session = LocalGroupSession()

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
                .padding(.top, 8)
                .padding(.horizontal, 20)

            TabView(selection: $bindableViewModel.selectedPage) {
                TodayScreenView(
                    groupName: session.displayGroupName,
                    members: members,
                    homeCountBreakfast: viewModel.homeCount(for: .breakfast, in: todayPlan),
                    homeCountLunch: viewModel.homeCount(for: .lunch, in: todayPlan),
                    homeCountDinner: viewModel.homeCount(for: .dinner, in: todayPlan),
                    statusProvider: { memberId, meal in
                        viewModel.status(for: memberId, mealTime: meal, in: todayPlan)
                    },
                    noteProvider: { memberId in
                        viewModel.note(for: memberId, in: todayPlan)
                    },
                    canEditMember: { memberId in
                        viewModel.canEdit(memberId: memberId, currentUserId: session.currentUserId)
                    },
                    onCycleStatus: { memberId, meal in
                        Task {
                            await viewModel.cycleStatus(
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
                    },
                    onOpenGroupSettings: {
                        viewModel.openGroupSettings()
                    }
                )
                .tag(HomePage.today)

                WeekScreenView(
                    plans: viewModel.plans.filter { $0.groupId == session.groupId },
                    onEditDate: { targetDate in
                        viewModel.openEditor(for: targetDate, canEdit: true)
                    }
                )
                .tag(HomePage.week)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.2), value: viewModel.selectedPage)
        }
        .background(AppThemeColor.baseBackground)
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
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { !session.isSetupCompleted },
                set: { _ in }
            )
        ) {
            GroupSetupView(
                onCreateGroup: { userName, groupName in
                    session.createGroup(userName: userName, groupName: groupName)
                },
                onJoinGroup: { userName, groupId in
                    session.joinGroup(userName: userName, groupId: groupId)
                }
            )
        }
        .task(id: session.groupId) {
            guard !AppRuntime.isPreview else { return }
            if session.isSetupCompleted {
                viewModel.startRealtimeSync(groupId: session.groupId)
                await viewModel.refreshNow(groupId: session.groupId)
            }
        }
        .onDisappear {
            viewModel.stopRealtimeSync()
        }
    }
}

/// 今日・今週タブを上部に表示するViewです。
private struct HomeTabHeader: View {
    @Binding var selectedPage: HomePage

    var body: some View {
        HStack(spacing: 28) {
            ForEach(HomePage.allCases) { page in
                Button {
                    selectedPage = page
                } label: {
                    VStack(spacing: 6) {
                        Text(page.title)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(selectedPage == page ? AppThemeColor.accent : .black)

                        Rectangle()
                            .fill(selectedPage == page ? AppThemeColor.accent : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(width: 54)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
