//
//  DashboardViews.swift
//  CaloBite
//
//  Created by Giulliano Suarez on 6/8/26.
//

import SwiftUI
import Charts
import SwiftData

// 1. Level & XP Dashboard View
struct LevelDashboardView: View {
    let biteLevel: Int
    let currentXP: Int
    let username: String
    let userAvatar: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(biteLevel) \(username)")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.purple)
                    Text("Bite XP: \(currentXP) / 150 to level up!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(.purple.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Text(userAvatar)
                        .font(.system(size: 26))
                }
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5).opacity(0.5))
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(Double(currentXP) / 150.0), height: 12)
                        .shadow(color: .purple.opacity(0.4), radius: 4, x: 0, y: 2)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.thinMaterial))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// 2. Daily Calorie Progress Widget
struct CalorieProgressWidgetView: View {
    let totalCalories: Double
    let dailyCalorieGoal: Double
    let totalCarbs: Double
    let dailyCarbGoal: Double
    let totalProtein: Double
    let dailyProteinGoal: Double
    let totalFat: Double
    let dailyFatGoal: Double
    @Binding var isCustomizeSheetPresented: Bool
    
    var body: some View {
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
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5).opacity(0.5), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    Circle()
                        .trim(from: 0, to: CGFloat(min(totalCalories / dailyCalorieGoal, 1.0)))
                        .stroke(LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    VStack {
                        Text("\(Int(max(dailyCalorieGoal - totalCalories, 0)))")
                            .font(.title2)
                            .bold()
                        Text("Left")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                
                VStack(spacing: 12) {
                    MacroBarItem(name: "Carbs", current: totalCarbs, target: dailyCarbGoal, color: .green)
                    MacroBarItem(name: "Protein", current: totalProtein, target: dailyProteinGoal, color: .blue)
                    MacroBarItem(name: "Fat", current: totalFat, target: dailyFatGoal, color: .yellow)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.thinMaterial))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// Support Item for Macro Bar Progress
struct MacroBarItem: View {
    let name: String
    let current: Double
    let target: Double
    let color: Color
    
    var body: some View {
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
                }
            }
            .frame(height: 6)
        }
    }
}

// 3. Weekly Performance Chart View
struct WeeklyPerformanceChartView: View {
    let summaries: [DailyCalorieSummary]
    let dailyCalorieGoal: Double
    
    var body: some View {
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
                ForEach(summaries) { summary in
                    BarMark(
                        x: .value("Day", summary.date, unit: .day),
                        y: .value("Calories", summary.calories)
                    )
                    .foregroundStyle(LinearGradient(colors: summary.calories >= dailyCalorieGoal ? [.red, .orange] : [.purple, .indigo], startPoint: .bottom, endPoint: .top))
                    .cornerRadius(6)
                }
                
                RuleMark(y: .value("Daily Target", dailyCalorieGoal))
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 4]))
                    .foregroundStyle(.orange)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal: \(Int(dailyCalorieGoal)) kcal")
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
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated)).foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                    AxisValueLabel().foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.thinMaterial))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// 4. Game Bottom Console Navigation Deck
struct GameBottomConsoleDeckView: View {
    var vm: CaloBiteViewModel
    @Binding var isCustomizeSheetPresented: Bool
    @Binding var isAddSheetPresented: Bool
    @Binding var exportedSpreadsheetURL: URL?
    @Binding var isPreparingSpreadsheet: Bool
    
    var body: some View {
        HStack(spacing: 30) {
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
                .offset(y: -20)
            }
            
            Group {
                if isPreparingSpreadsheet {
                    ProgressView().tint(.purple)
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
        .background(RoundedRectangle(cornerRadius: 32).fill(.ultraThinMaterial).shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: -2))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// 5. Daily Log List Section (Updated with Instant Delete Action Buttons)
struct LogsSectionView: View {
    let dailyLogs: [LogEntry]
    let onDelete: (LogEntry) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Logged Quests (Today)")
                .font(.headline)
                .bold()
                .padding(.horizontal, 4)
            
            if dailyLogs.isEmpty {
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
                ForEach(dailyLogs) { log in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.foodName)
                                .font(.body)
                                .bold()
                            Text("\(Int(log.grams))g")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("+\(Int(log.calories)) kcal")
                                .bold()
                                .foregroundStyle(.orange)
                            Text("+\(log.xpEarned) XP")
                                .font(.system(size: 10))
                                .bold()
                                .foregroundStyle(.purple)
                        }
                        
                        // Action: Immediate Card Deletion with tactile feedback animation
                        Button {
                            onDelete(log)
                        } label: {
                            Image(systemName: "trash.fill")
                                .font(.body)
                                .foregroundStyle(.red.opacity(0.85))
                                .padding(8)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
                    .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                }
            }
        }
    }
}

// 6. Level Up Animation Overlay Sheet
struct LevelUpCelebrationOverlay: View {
    let biteLevel: Int
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🎉 LEVEL UP! 🎉")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.yellow)
                Text("You have reached Level \(biteLevel)")
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
