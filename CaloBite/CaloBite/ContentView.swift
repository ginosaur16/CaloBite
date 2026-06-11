//
//  ContentView.swift
//  CaloBite
//
//  Created by Giulliano Suarez on 6/8/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CaloBiteViewModel?
    
    // Core SwiftData query to dynamically update historical stats in real-time
    @Query(sort: \LogEntry.timestamp, order: .reverse) private var allLogs: [LogEntry]
    
    // App Flow Control States
    @State private var isShowingSplash = true
    @AppStorage("hasCompletedProfileSetup") private var hasCompletedProfileSetup = false
    @AppStorage("username") private var username = "Calorie Warrior"
    @AppStorage("userAvatar") private var userAvatar = "🛡️"
    
    // View Sheets States
    @State private var isAddSheetPresented = false
    @State private var isCustomizeSheetPresented = false
    @State private var exportedSpreadsheetURL: URL? = nil
    @State private var isPreparingSpreadsheet = false
    
    var body: some View {
        Group {
            if isShowingSplash {
                SplashView(isShowingSplash: $isShowingSplash)
            } else if !hasCompletedProfileSetup {
                CharacterCreationView(
                    username: $username,
                    userAvatar: $userAvatar,
                    hasCompletedProfileSetup: $hasCompletedProfileSetup
                )
            } else {
                mainAppDashboard
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = CaloBiteViewModel(modelContext: modelContext)
            }
        }
    }
    
    // MARK: - Main Dashboard Container
    private var mainAppDashboard: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    ZStack(alignment: .bottom) {
                        // Immersive Gamified Gradient Background
                        LinearGradient(
                            colors: [
                                .purple.opacity(0.18),
                                .indigo.opacity(0.15),
                                Color(.systemBackground)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                        
                        ScrollView {
                            VStack(spacing: 20) {
                                LevelDashboardView(
                                    biteLevel: vm.biteLevel,
                                    currentXP: vm.currentXP,
                                    username: username,
                                    userAvatar: userAvatar
                                )
                                
                                CalorieProgressWidgetView(
                                    totalCalories: vm.totalCalories,
                                    dailyCalorieGoal: vm.dailyCalorieGoal,
                                    totalCarbs: vm.totalCarbs,
                                    dailyCarbGoal: vm.dailyCarbGoal,
                                    totalProtein: vm.totalProtein,
                                    dailyProteinGoal: vm.dailyProteinGoal,
                                    totalFat: vm.totalFat,
                                    dailyFatGoal: vm.dailyFatGoal,
                                    isCustomizeSheetPresented: $isCustomizeSheetPresented
                                )
                                
                                WeeklyPerformanceChartView(
                                    summaries: getRollingSevenDaysSummaries(),
                                    dailyCalorieGoal: vm.dailyCalorieGoal
                                )
                                
                                LogsSectionView(
                                    dailyLogs: vm.dailyLogs,
                                    onDelete: { log in vm.deleteLog(log) }
                                )
                                
                                Color.clear.frame(height: 100)
                            }
                            .padding()
                        }
                        
                        GameBottomConsoleDeckView(
                            vm: vm,
                            isCustomizeSheetPresented: $isCustomizeSheetPresented,
                            isAddSheetPresented: $isAddSheetPresented,
                            exportedSpreadsheetURL: $exportedSpreadsheetURL,
                            isPreparingSpreadsheet: $isPreparingSpreadsheet
                        )
                        
                        if vm.showLevelUpAnimation {
                            LevelUpCelebrationOverlay(biteLevel: vm.biteLevel)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("CALOBITE")
                                .font(.system(.title3, design: .monospaced))
                                .bold()
                                .tracking(6)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .indigo],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                    .sheet(isPresented: $isAddSheetPresented) {
                        AddFoodLogSheet(vm: vm)
                    }
                    .sheet(isPresented: $isCustomizeSheetPresented) {
                        CustomizeGoalsSheet(vm: vm)
                    }
                } else {
                    ProgressView("Entering the Arena...")
                }
            }
        }
    }
    
    // Core math helper to aggregate database entries into Calendar Days
    private func getRollingSevenDaysSummaries() -> [DailyCalorieSummary] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).reversed().map { offset in
            let targetDate = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let startOfDay = calendar.startOfDay(for: targetDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let dailyTotal = allLogs.filter { log in
                log.timestamp >= startOfDay && log.timestamp < endOfDay
            }.reduce(0.0) { $0 + $1.calories }
            
            return DailyCalorieSummary(date: startOfDay, calories: dailyTotal)
        }
    }
}
