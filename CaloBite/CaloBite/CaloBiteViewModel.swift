//
//  CaloBiteViewModel.swift
//  CaloBite
//
//  Created by Giulliano Suarez on 6/8/26.
//

import Foundation
import SwiftData
import Observation
import SwiftUI

@Observable
final class CaloBiteViewModel {
    private var modelContext: ModelContext
    
    // Core game stats & queries
    var searchQuery: String = ""
    var selectedCategory: String = "All"
    var selectedFood: FoodReference? = nil
    var inputGrams: Double = 100.0
    
    // Gamification properties
    var currentXP: Int = 0
    var biteLevel: Int = 1
    var showLevelUpAnimation: Bool = false
    
    // Storage Cache
    var foodDatabase: [FoodReference] = []
    var dailyLogs: [LogEntry] = []
    
    // Customizable persistent targets (using UserDefaults + didSet for seamless UI updates)
    var dailyCalorieGoal: Double = 2000.0 {
        didSet { UserDefaults.standard.set(dailyCalorieGoal, forKey: "dailyCalorieGoal") }
    }
    var dailyCarbGoal: Double = 250.0 {
        didSet { UserDefaults.standard.set(dailyCarbGoal, forKey: "dailyCarbGoal") }
    }
    var dailyProteinGoal: Double = 130.0 {
        didSet { UserDefaults.standard.set(dailyProteinGoal, forKey: "dailyProteinGoal") }
    }
    var dailyFatGoal: Double = 65.0 {
        didSet { UserDefaults.standard.set(dailyFatGoal, forKey: "dailyFatGoal") }
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Load targets from local memory
        let savedCal = UserDefaults.standard.double(forKey: "dailyCalorieGoal")
        let savedCarb = UserDefaults.standard.double(forKey: "dailyCarbGoal")
        let savedProt = UserDefaults.standard.double(forKey: "dailyProteinGoal")
        let savedFat = UserDefaults.standard.double(forKey: "dailyFatGoal")
        
        self.dailyCalorieGoal = savedCal == 0 ? 2000.0 : savedCal
        self.dailyCarbGoal = savedCarb == 0 ? 250.0 : savedCarb
        self.dailyProteinGoal = savedProt == 0 ? 130.0 : savedProt
        self.dailyFatGoal = savedFat == 0 ? 65.0 : savedFat
        
        Task {
            await initializeDatabase()
            await loadDailyLogs()
        }
    }
    
    // Runs on MainActor to keep SwiftData state synchronous with UI
    @MainActor
    func initializeDatabase() async {
        do {
            let descriptor = FetchDescriptor<FoodReference>()
            let existing = try modelContext.fetch(descriptor)
            
            // If the database has missing reference items or is empty, seed it
            if existing.isEmpty {
                for food in FoodReference.defaultFoods {
                    modelContext.insert(food)
                }
                try modelContext.save()
            } else if existing.count < FoodReference.defaultFoods.count {
                // Seed new missing foods introduced in updates
                let existingNames = Set(existing.map { $0.name })
                for food in FoodReference.defaultFoods {
                    if !existingNames.contains(food.name) {
                        modelContext.insert(food)
                    }
                }
                try modelContext.save()
            }
            
            foodDatabase = try modelContext.fetch(FetchDescriptor<FoodReference>(sortBy: [SortDescriptor(\.name)]))
        } catch {
            print("Failed to load reference foods: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func loadDailyLogs() async {
        do {
            let startOfToday = Calendar.current.startOfDay(for: Date())
            let descriptor = FetchDescriptor<LogEntry>(
                predicate: #Predicate<LogEntry> { $0.timestamp >= startOfToday },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            dailyLogs = try modelContext.fetch(descriptor)
            updateXPState()
        } catch {
            print("Failed to fetch daily logs: \(error.localizedDescription)")
        }
    }
    
    // Dynamic Stats Calculations
    var totalCalories: Double { dailyLogs.reduce(0) { $0 + $1.calories } }
    var totalCarbs: Double { dailyLogs.reduce(0) { $0 + $1.carbs } }
    var totalProtein: Double { dailyLogs.reduce(0) { $0 + $1.protein } }
    var totalFat: Double { dailyLogs.reduce(0) { $0 + $1.fat } }
    
    // Category filtered search math
    var filteredFoods: [FoodReference] {
        var baseList = foodDatabase
        
        if selectedCategory != "All" {
            baseList = baseList.filter { $0.category == selectedCategory }
        }
        
        if !searchQuery.isEmpty {
            baseList = baseList.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
        
        return baseList
    }
    
    @MainActor
    func logFood(food: FoodReference, grams: Double) async {
        let calories = food.caloriesPerGram * grams
        let carbs = food.carbsPerGram * grams
        let protein = food.proteinPerGram * grams
        let fat = food.fatPerGram * grams
        
        // Gamified reward: XP is scaled based on weight logged
        let xpGained = Int(grams * 0.4) + 10
        
        let newEntry = LogEntry(
            foodName: food.name,
            grams: grams,
            calories: calories,
            carbs: carbs,
            protein: protein,
            fat: fat,
            xpEarned: xpGained
        )
        
        modelContext.insert(newEntry)
        
        do {
            try modelContext.save()
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                dailyLogs.insert(newEntry, at: 0)
                updateXPState()
            }
            
            // Check for Level Up!
            let oldLevel = biteLevel
            let totalAccumulatedXP = dailyLogs.reduce(0) { $0 + $1.xpEarned }
            let newLevel = (totalAccumulatedXP / 150) + 1
            
            if newLevel > oldLevel {
                withAnimation(.bouncy(duration: 1.0)) {
                    biteLevel = newLevel
                    showLevelUpAnimation = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        self.showLevelUpAnimation = false
                    }
                }
            }
            
        } catch {
            print("Failed to log entry: \(error)")
        }
    }
    
    @MainActor
    func deleteLog(at offsets: IndexSet) {
        for index in offsets {
            let entry = dailyLogs[index]
            modelContext.delete(entry)
        }
        
        do {
            try modelContext.save()
            dailyLogs.remove(atOffsets: offsets)
            updateXPState()
        } catch {
            print("Failed to delete meal log: \(error)")
        }
    }
    
    private func updateXPState() {
        let totalAccumulatedXP = dailyLogs.reduce(0) { $0 + $1.xpEarned }
        biteLevel = (totalAccumulatedXP / 150) + 1
        currentXP = totalAccumulatedXP % 150
    }
    
    // MARK: - Custom Food Creator
    @MainActor
    func addCustomFood(name: String, calories100g: Double, carbs100g: Double, protein100g: Double, fat100g: Double) -> FoodReference {
        let newFood = FoodReference(
            name: name,
            caloriesPerGram: calories100g / 100.0,
            carbsPerGram: carbs100g / 100.0,
            proteinPerGram: protein100g / 100.0,
            fatPerGram: fat100g / 100.0,
            category: "🛠️ Custom"
        )
        modelContext.insert(newFood)
        do {
            try modelContext.save()
            // Reload the food database list
            foodDatabase = try modelContext.fetch(FetchDescriptor<FoodReference>(sortBy: [SortDescriptor(\.name)]))
        } catch {
            print("Failed to save custom food: \(error)")
        }
        return newFood
    }
    
    // MARK: - MVVM / Swift Concurrency spreadsheet exporter
    /// Generates a local CSV File URL containing the history of all logs in the database.
    func generateCSVExport() async -> URL? {
        let fetchDescriptor = FetchDescriptor<LogEntry>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        
        guard let allLogs = try? modelContext.fetch(fetchDescriptor) else { return nil }
        
        // Build raw CSV representation
        var csvString = "Timestamp,Food Item,Weight (g),Calories (kcal),Carbs (g),Protein (g),Fat (g),XP Earned\n"
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        
        for log in allLogs {
            let safeName = log.foodName.replacingOccurrences(of: "\"", with: "\"\"")
            let dateStr = formatter.string(from: log.timestamp)
            let line = "\"\(dateStr)\",\"\(safeName)\",\(log.grams),\(log.calories),\(log.carbs),\(log.protein),\(log.fat),\(log.xpEarned)\n"
            csvString.append(line)
        }
        
        // Save file onto temporary disk location
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("CaloBite_Quest_Logs.csv")
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing CSV file: \(error)")
            return nil
        }
    }
}
