//
//  ContentView.swift
//  CaloBite
//
//  Created by Giulliano Suarez on 6/8/26.
//

import SwiftUI
import SwiftData
import Charts // Native high-performance chart rendering

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CaloBiteViewModel?
    
    // Core SwiftData query to dynamically update historical stats in real-time
    @Query(sort: \LogEntry.timestamp, order: .reverse) private var allLogs: [LogEntry]
    
    // Splash screen state control
    @State private var isShowingSplash = true
    @State private var splashScale: CGFloat = 0.85
    @State private var splashOpacity: Double = 0.0
    
    // Screen triggers
    @State private var isAddSheetPresented = false
    @State private var isCustomizeSheetPresented = false
    
    // State to hold the exported CSV URL for the native ShareLink share sheet
    @State private var exportedSpreadsheetURL: URL? = nil
    @State private var isPreparingSpreadsheet = false
    
    var body: some View {
        Group {
            if isShowingSplash {
                // Gamified Splash Screen Transition View
                splashView
            } else {
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
                                        // Level & XP Character Avatar Widget
                                        levelDashboard(vm: vm)
                                        
                                        // Interactive Macro Progress Ring Matrix
                                        calorieProgressWidget(vm: vm)
                                        
                                        // Dynamic 7-Day Calorie Chart Widget
                                        weeklyPerformanceChart(vm: vm)
                                        
                                        // List of logged elements
                                        logsSection(vm: vm)
                                        
                                        // Bottom spacing spacer block to ensure elements don't get blocked by the Floating Bottom Console
                                        Color.clear.frame(height: 100)
                                    }
                                    .padding()
                                }
                                
                                // Interactive Game Bottom Hub Console
                                gameBottomConsoleDeck(vm: vm)
                                
                                // Level Up Toast Alert Overlay
                                if vm.showLevelUpAnimation {
                                    levelUpCelebrationOverlay(vm: vm)
                                }
                            }
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                // Center-justified customized cosmic title matching the splash screen design
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
        }
        .onAppear {
            if viewModel == nil {
                viewModel = CaloBiteViewModel(modelContext: modelContext)
            }
        }
    }
    
    // MARK: - Splash Screen View
    private var splashView: some View {
        ZStack {
            // Match the core dark-purple aesthetic
            LinearGradient(
                colors: [
                    .purple.opacity(0.25),
                    .indigo.opacity(0.20),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Main brand logo with gamified scale, bounce, and a purple shadow aura
                Image("iconers")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: .purple.opacity(0.4), radius: 25, x: 0, y: 12)
                    .scaleEffect(splashScale)
                    .opacity(splashOpacity)
                
                VStack(spacing: 8) {
                    Text("CALOBITE")
                        .font(.system(.largeTitle, design: .monospaced))
                        .bold()
                        .tracking(8)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("FUEL YOUR QUEST")
                        .font(.system(.caption, design: .monospaced))
                        .bold()
                        .tracking(4)
                        .foregroundStyle(.secondary)
                }
                .opacity(splashOpacity)
                .offset(y: isShowingSplash ? 0 : 20)
                
                Spacer()
                
                // Loading metrics footer
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.purple)
                    
                    Text("Readying Avatar...")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .opacity(splashOpacity)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Soft spring animation for entering elements
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7, blendDuration: 0.5)) {
                splashScale = 1.0
                splashOpacity = 1.0
            }
            
            // Asynchronous delay using modern Swift Concurrency
            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 second delay
                withAnimation(.easeInOut(duration: 0.6)) {
                    isShowingSplash = false
                }
            }
        }
    }
    
    // MARK: - Level Dashboard
    private func levelDashboard(vm: CaloBiteViewModel) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(vm.biteLevel) Calorie Warrior")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.purple)
                    
                    Text("Bite XP: \(vm.currentXP) / 150 to level up!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                // Character Badge Avatar
                ZStack {
                    Circle()
                        .fill(.purple.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Text("🛡️")
                        .font(.system(size: 26))
                }
            }
            
            // Experience Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5).opacity(0.5))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(Double(vm.currentXP) / 150.0), height: 12)
                        .shadow(color: .purple.opacity(0.4), radius: 4, x: 0, y: 2)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: vm.currentXP)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.thinMaterial))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Interactive Macro Widgets
    private func calorieProgressWidget(vm: CaloBiteViewModel) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Mana Pool")
                        .font(.headline)
                        .bold()
                    Text("Calorie & macro usage overview")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                Button {
                    isCustomizeSheetPresented = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Tune")
                    }
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.12))
                    .cornerRadius(12)
                }
            }
            
            HStack(spacing: 16) {
                // Large circular indicator
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5).opacity(0.5), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(min(vm.totalCalories / vm.dailyCalorieGoal, 1.0)))
                        .stroke(
                            LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.0), value: vm.totalCalories)
                    
                    VStack {
                        Text("\(Int(max(vm.dailyCalorieGoal - vm.totalCalories, 0)))")
                            .font(.title2)
                            .bold()
                        Text("Left")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Details
                VStack(spacing: 12) {
                    macroBar(name: "Carbs", current: vm.totalCarbs, target: vm.dailyCarbGoal, color: .green)
                    macroBar(name: "Protein", current: vm.totalProtein, target: vm.dailyProteinGoal, color: .blue)
                    macroBar(name: "Fat", current: vm.totalFat, target: vm.dailyFatGoal, color: .yellow)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.thinMaterial))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private func macroBar(name: String, current: Double, target: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.caption)
                    .bold()
                Spacer()
                Text("\(Int(current))g / \(Int(target))g")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6).opacity(0.5))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(current / target, 1.0)), height: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: current)
                }
            }
            .frame(height: 6)
        }
    }
    
    // MARK: - Weekly Performance Chart (Rolling 7-Day History)
    private func weeklyPerformanceChart(vm: CaloBiteViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quest Chronicle")
                    .font(.headline)
                    .bold()
                Text("Your total energy consumption over the last 7 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Chart {
                // Populate the last 7 days dynamically
                ForEach(getRollingSevenDaysSummaries()) { summary in
                    BarMark(
                        x: .value("Day", summary.date, unit: .day),
                        y: .value("Calories", summary.calories)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: summary.calories >= vm.dailyCalorieGoal ? [.red, .orange] : [.purple, .indigo],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(6)
                }
                
                // Active Target Goal Reference Line
                RuleMark(
                    y: .value("Daily Target", vm.dailyCalorieGoal)
                )
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 4]))
                .foregroundStyle(.orange)
                .annotation(position: .top, alignment: .trailing) {
                    Text("Goal: \(Int(vm.dailyCalorieGoal)) kcal")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .cornerRadius(4)
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.thinMaterial))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    // Helper object to model daily sums for the graph
    struct DailyCalorieSummary: Identifiable {
        let id = UUID()
        let date: Date
        let calories: Double
    }
    
    // Core math to aggregate the database records into calendar days
    private func getRollingSevenDaysSummaries() -> [DailyCalorieSummary] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).reversed().map { offset in
            let targetDate = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let startOfDay = calendar.startOfDay(for: targetDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            // Filter all SwiftData logs matching this day's range
            let dailyTotal = allLogs.filter { log in
                log.timestamp >= startOfDay && log.timestamp < endOfDay
            }.reduce(0.0) { $0 + $1.calories }
            
            return DailyCalorieSummary(date: startOfDay, calories: dailyTotal)
        }
    }
    
    // MARK: - Game Bottom Console Deck (Floating Tab-style Hub)
    private func gameBottomConsoleDeck(vm: CaloBiteViewModel) -> some View {
        HStack(spacing: 30) {
            // Left Action: Edit Targets
            Button {
                isCustomizeSheetPresented = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                    Text("Targets")
                        .font(.system(size: 10))
                        .bold()
                }
                .foregroundStyle(.purple)
            }
            .frame(maxWidth: .infinity)
            
            // Center Core: Floating Pulsing Addition Button
            Button {
                isAddSheetPresented = true
            } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 60, height: 60)
                        .shadow(color: .purple.opacity(0.4), radius: 6, x: 0, y: 4)
                    
                    Image(systemName: "plus")
                        .font(.title)
                        .bold()
                        .foregroundStyle(.white)
                }
                .offset(y: -20) // Floating orb aesthetic
            }
            
            // Right Action: Dynamic Asynchronous CSV Share Link
            Group {
                if isPreparingSpreadsheet {
                    ProgressView()
                        .tint(.purple)
                } else if let url = exportedSpreadsheetURL {
                    ShareLink(item: url) {
                        VStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.title3)
                                .foregroundStyle(.green)
                            Text("Export Ready")
                                .font(.system(size: 10))
                                .bold()
                                .foregroundStyle(.green)
                        }
                    }
                } else {
                    Button {
                        Task {
                            isPreparingSpreadsheet = true
                            exportedSpreadsheetURL = await vm.generateCSVExport()
                            isPreparingSpreadsheet = false
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "doc.text.below.ecg.fill")
                                .font(.title3)
                            Text("Spreadsheet")
                                .font(.system(size: 10))
                                .bold()
                        }
                        .foregroundStyle(.purple)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: -2)
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
        .onChange(of: vm.dailyLogs) { _, _ in
            exportedSpreadsheetURL = nil // Wipe cached URL when meals state changes
        }
    }
    
    // MARK: - Daily Logs List
    private func logsSection(vm: CaloBiteViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Logged Quests (Today)")
                .font(.headline)
                .bold()
                .padding(.horizontal, 4)
            
            if vm.dailyLogs.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "square.and.pencil")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No records found today.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(RoundedRectangle(cornerRadius: 20).fill(.thinMaterial))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            } else {
                ForEach(vm.dailyLogs) { log in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(log.foodName)
                                .font(.body)
                                .bold()
                            Text("\(Int(log.grams))g")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("+\(Int(log.calories)) kcal")
                                .bold()
                                .foregroundStyle(.orange)
                            Text("+\(log.xpEarned) XP")
                                .font(.system(size: 10))
                                .bold()
                                .foregroundStyle(.purple)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
                    .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                }
                .onDelete { indexes in
                    vm.deleteLog(at: indexes)
                }
            }
        }
    }
    
    // MARK: - Level Up Overlay
    private func levelUpCelebrationOverlay(vm: CaloBiteViewModel) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("🎉 LEVEL UP! 🎉")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.yellow)
                
                Text("You have reached Level \(vm.biteLevel)")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)
                
                Text("Keep logging your items and fuel your avatar!")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.yellow)
                    .shadow(color: .yellow.opacity(0.6), radius: 10)
            }
            .padding(40)
            .background(RoundedRectangle(cornerRadius: 30).fill(Color(.systemBackground).opacity(0.15)).background(.ultraThinMaterial))
            .cornerRadius(30)
            .padding()
        }
    }
}

// MARK: - Customize Goals Sheet View
struct CustomizeGoalsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: CaloBiteViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        .purple.opacity(0.12),
                        .indigo.opacity(0.08),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 48))
                            .foregroundStyle(.purple)
                            .padding(.top, 16)
                        
                        Text("Customize Target Goals")
                            .font(.title2)
                            .bold()
                        
                        Text("Adjust your energy parameters to custom fit your journey.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 32)
                        
                        VStack(spacing: 20) {
                            // Calories Slider
                            goalTuningSlider(
                                title: "Calories",
                                value: $vm.dailyCalorieGoal,
                                bounds: 1000...5000,
                                step: 50,
                                unit: "kcal",
                                tint: .orange
                            )
                            
                            // Carbs Slider
                            goalTuningSlider(
                                title: "Carbs Target",
                                value: $vm.dailyCarbGoal,
                                bounds: 50...400,
                                step: 5,
                                unit: "g",
                                tint: .green
                            )
                            
                            // Protein Slider
                            goalTuningSlider(
                                title: "Protein Target",
                                value: $vm.dailyProteinGoal,
                                bounds: 40...300,
                                step: 5,
                                unit: "g",
                                tint: .blue
                            )
                            
                            // Fat Slider
                            goalTuningSlider(
                                title: "Fat Target",
                                value: $vm.dailyFatGoal,
                                bounds: 20...150,
                                step: 5,
                                unit: "g",
                                tint: .yellow
                            )
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .padding(.horizontal)
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Save Targets & Lock-In")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                                .foregroundStyle(.white)
                                .cornerRadius(16)
                                .shadow(color: .purple.opacity(0.2), radius: 5, x: 0, y: 3)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("Tuner Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func goalTuningSlider(
        title: String,
        value: Binding<Double>,
        bounds: ClosedRange<Double>,
        step: Double,
        unit: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .bold()
                    .font(.subheadline)
                Spacer()
                Text("\(Int(value.wrappedValue)) \(unit)")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(tint)
            }
            
            Slider(value: value, in: bounds, step: step)
                .tint(tint)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Food Interactive Log Sheet
struct AddFoodLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: CaloBiteViewModel
    
    @State private var weightGrams: Double = 100.0
    @State private var isCustomFoodSheetPresented = false
    
    // Constant list of categories for the interactive game filter pill deck
    let categories = ["All", "🍎 Fruits", "🍗 Proteins", "🍚 Carbs", "🥜 Fats", "🥛 Dairy", "🥦 Veggies", "🛠️ Custom"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient for the add food sheet
                LinearGradient(
                    colors: [
                        .purple.opacity(0.12),
                        .indigo.opacity(0.08),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Live Input Search Bar with standard Binding syntax
                    SearchBar(text: $vm.searchQuery)
                        .padding([.horizontal, .top])
                    
                    // Gamified Category Selection Bar (Filter Deck)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        vm.selectedCategory = category
                                    }
                                } label: {
                                    Text(category)
                                        .font(.subheadline)
                                        .bold()
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(vm.selectedCategory == category ? Color.purple : Color.purple.opacity(0.12))
                                        .foregroundStyle(vm.selectedCategory == category ? .white : .purple)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)
                    
                    List {
                        Section {
                            ForEach(vm.filteredFoods) { food in
                                Button {
                                    withAnimation(.spring) {
                                        vm.selectedFood = food
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(food.name)
                                                .font(.body)
                                                .bold()
                                            Text("\(food.category)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if vm.selectedFood?.id == food.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.purple)
                                        }
                                    }
                                }
                                .foregroundStyle(.primary)
                            }
                        } header: {
                            HStack {
                                Text("Search Results (\(vm.filteredFoods.count))")
                                Spacer()
                                Button {
                                    isCustomFoodSheetPresented = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Create Custom")
                                    }
                                    .font(.caption)
                                    .bold()
                                    .foregroundStyle(.purple)
                                }
                            }
                            .textCase(nil)
                        }
                        
                        // Empty search result fallback with call-to-action
                        if vm.filteredFoods.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "questionmark.folder.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                                
                                Text("Can't find your food?")
                                    .font(.headline)
                                    .bold()
                                
                                Text("No worries! Create a custom food item to log it and earn XP.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                
                                Button {
                                    isCustomFoodSheetPresented = true
                                } label: {
                                    HStack {
                                        Image(systemName: "plus")
                                        Text("Create Custom Food 🛠️")
                                    }
                                    .bold()
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.purple)
                                    .foregroundStyle(.white)
                                    .cornerRadius(12)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .scrollContentBackground(.hidden) // Allows the underlying gradient background to show through
                    
                    // Interactive dynamic logging panel
                    if let selected = vm.selectedFood {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Calculating Details:")
                                    .font(.caption)
                                    .bold()
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(selected.name)
                                    .bold()
                            }
                            
                            // Interactive Slider
                            VStack {
                                HStack {
                                    Text("Portion Size")
                                        .bold()
                                    Spacer()
                                    Text("\(Int(weightGrams)) grams")
                                        .font(.title3)
                                        .bold()
                                        .foregroundStyle(.purple)
                                }
                                Slider(value: $weightGrams, in: 10...500, step: 5)
                                    .tint(.purple)
                            }
                            
                            // Live dynamic math updates
                            HStack(spacing: 12) {
                                macroPreviewTile(name: "Calories", value: "\(Int(selected.caloriesPerGram * weightGrams)) kcal", color: .orange)
                                macroPreviewTile(name: "Carbs", value: "\(Int(selected.carbsPerGram * weightGrams))g", color: .green)
                                macroPreviewTile(name: "Protein", value: "\(Int(selected.proteinPerGram * weightGrams))g", color: .blue)
                                macroPreviewTile(name: "Fat", value: "\(Int(selected.fatPerGram * weightGrams))g", color: .yellow)
                            }
                            
                            Button {
                                Task {
                                    await vm.logFood(food: selected, grams: weightGrams)
                                    dismiss()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Log & Earn XP!")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                                .foregroundStyle(.white)
                                .bold()
                                .cornerRadius(16)
                                .shadow(color: .purple.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Add Quest Fuel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isCustomFoodSheetPresented) {
                CreateCustomFoodSheet(vm: vm)
            }
        }
    }
    
    private func macroPreviewTile(name: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.system(size: 10))
                .bold()
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .bold()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground).opacity(0.7)))
    }
}

// MARK: - Create Custom Food Sheet
struct CreateCustomFoodSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: CaloBiteViewModel
    
    // Form Input States (Nutrients are based on the industry-standard per 100g database standard)
    @State private var customName: String = ""
    @State private var inputCalories: Double = 150.0
    @State private var inputCarbs: Double = 15.0
    @State private var inputProtein: Double = 10.0
    @State private var inputFat: Double = 5.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        .purple.opacity(0.12),
                        .indigo.opacity(0.08),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.purple)
                            .padding(.top, 16)
                        
                        Text("Create Custom Food")
                            .font(.title2)
                            .bold()
                        
                        Text("Input the nutrients *per 100g* portion size. We will automatically convert and calculate your personalized serving size parameters.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 32)
                        
                        VStack(spacing: 16) {
                            // Food Name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Food Name")
                                    .bold()
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("e.g. Homemade Meatballs", text: $customName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            Divider()
                            
                            // Calories Slider
                            macroCustomInputRow(title: "Calories (per 100g)", value: $inputCalories, bounds: 0...900, step: 5, unit: "kcal", tint: .orange)
                            
                            // Carbs Slider
                            macroCustomInputRow(title: "Carbohydrates (per 100g)", value: $inputCarbs, bounds: 0...100, step: 1, unit: "g", tint: .green)
                            
                            // Protein Slider
                            macroCustomInputRow(title: "Protein (per 100g)", value: $inputProtein, bounds: 0...100, step: 1, unit: "g", tint: .blue)
                            
                            // Fat Slider
                            macroCustomInputRow(title: "Fats (per 100g)", value: $inputFat, bounds: 0...100, step: 1, unit: "g", tint: .yellow)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .padding(.horizontal)
                        
                        Button {
                            // Validation: require a name
                            guard !customName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            
                            // Save to SwiftData using VM architecture
                            let newFood = vm.addCustomFood(
                                name: customName,
                                calories100g: inputCalories,
                                carbs100g: inputCarbs,
                                protein100g: inputProtein,
                                fat100g: inputFat
                            )
                            
                            // Instantly select the newly created custom food
                            withAnimation(.spring) {
                                vm.selectedFood = newFood
                            }
                            dismiss()
                        } label: {
                            Text("Create & Lock-In Food Reference")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(customName.isEmpty ? Color.gray : Color.purple)
                                .foregroundStyle(.white)
                                .cornerRadius(16)
                        }
                        .disabled(customName.isEmpty)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("Custom Forge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func macroCustomInputRow(
        title: String,
        value: Binding<Double>,
        bounds: ClosedRange<Double>,
        step: Double,
        unit: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .bold()
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value.wrappedValue)) \(unit)")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(tint)
            }
            
            Slider(value: value, in: bounds, step: step)
                .tint(tint)
        }
        .padding(.vertical, 2)
    }
}

// Custom Search Bar Component with corrected Binding wrapper type
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search common foods...", text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodReference.self, LogEntry.self], inMemory: true)
}
