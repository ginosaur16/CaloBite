//
//  Models.swift
//  CaloBite
//
//  Created by Giulliano Suarez on 6/8/26.
//

import Foundation
import SwiftData

// MARK: - Enums for UserProfile
enum Gender: String, Codable, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    var id: String { self.rawValue }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary = "Sedentary (little to no exercise)"
    case lightlyActive = "Lightly Active (light exercise/sports 1-3 days/week)"
    case moderatelyActive = "Moderately Active (moderate exercise/sports 3-5 days/week)"
    case veryActive = "Very Active (hard exercise/sports 6-7 days/week)"
    case extraActive = "Extra Active (very hard exercise/sports & physical job)"
    var id: String { self.rawValue }
    
    // Multiplier for Basal Metabolic Rate (BMR) to calculate Total Daily Energy Expenditure (TDEE)
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive: return 1.725
        case .extraActive: return 1.9
        }
    }
}

enum WeightGoal: String, Codable, CaseIterable, Identifiable {
    case lose = "Lose Weight (500 kcal deficit)"
    case maintain = "Maintain Weight"
    case gain = "Gain Weight (500 kcal surplus)"
    var id: String { self.rawValue }
    
    var calorieAdjustment: Double {
        switch self {
        case .lose: return -500
        case .maintain: return 0
        case .gain: return 500
        }
    }
}

// MARK: - Daily Calorie Output Helper Model (Globally Shared)
struct DailyCalorieSummary: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
}

// MARK: - UserProfile Model
@Model
final class UserProfile {
    var id: UUID
    var name: String
    var age: Int
    var heightCm: Double
    var currentWeightKg: Double
    var gender: Gender
    var activityLevel: ActivityLevel
    var weightGoal: WeightGoal
    
    // Macro goals (can be overridden by user)
    var dailyCalorieGoal: Double
    var dailyCarbGoal: Double
    var dailyProteinGoal: Double
    var dailyFatGoal: Double
    
    // Gamification properties
    var currentXP: Int
    var biteLevel: Int
    
    // Relationship to LogEntry (logs owned by this user profile)
    @Relationship(deleteRule: .cascade, inverse: \LogEntry.userProfile)
    var logs: [LogEntry]? // Optional for now, will be populated
    
    init(id: UUID = UUID(), name: String, age: Int, heightCm: Double, currentWeightKg: Double, gender: Gender, activityLevel: ActivityLevel, weightGoal: WeightGoal, currentXP: Int = 0, biteLevel: Int = 1) {
        // Phase 1: Initialize all direct stored properties first
        self.id = id
        self.name = name
        self.age = age
        self.heightCm = heightCm
        self.currentWeightKg = currentWeightKg
        self.gender = gender
        self.activityLevel = activityLevel
        self.weightGoal = weightGoal
        self.currentXP = currentXP
        self.biteLevel = biteLevel
        
        // Initialize other stored properties with dummy/placeholder values
        // These will be immediately overwritten in Phase 2
        self.dailyCalorieGoal = 0
        self.dailyCarbGoal = 0
        self.dailyProteinGoal = 0
        self.dailyFatGoal = 0
        
        // Phase 2: Now that all stored properties have an initial value,
        // we can safely use 'self' or call methods that depend on 'self'.
        // Calculate initial goals based on health metrics provided in init parameters
        let calculatedBMR: Double
        switch gender {
        case .male:
            calculatedBMR = (10 * currentWeightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        case .female:
            calculatedBMR = (10 * currentWeightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        }
        
        let calculatedTDEE = calculatedBMR * activityLevel.multiplier
        let initialDailyCalories = calculatedTDEE + weightGoal.calorieAdjustment
        
        self.dailyCalorieGoal = initialDailyCalories
        self.dailyCarbGoal = UserProfile.dailyCarbByCalories(calories: initialDailyCalories)
        self.dailyProteinGoal = UserProfile.dailyProteinByWeight(weightKg: currentWeightKg, goal: weightGoal)
        self.dailyFatGoal = UserProfile.dailyFatByCalories(calories: initialDailyCalories)
    }
    
    // MARK: - Health & Goal Calculations (derived properties)
    
    // Basal Metabolic Rate (BMR) calculation using Mifflin-St Jeor Equation
    var bmr: Double {
        switch gender {
        case .male:
            return (10 * currentWeightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        case .female:
            return (10 * currentWeightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        }
    }
    
    // Total Daily Energy Expenditure (TDEE)
    var tdee: Double {
        bmr * activityLevel.multiplier
    }
    
    // Recommended daily calories based on TDEE and weight goal
    var recommendedDailyCalories: Double {
        tdee + weightGoal.calorieAdjustment
    }
    
    // MARK: - Default Macro Calculations (based on common guidelines)
    // These functions can be used to set initial macro goals
    static func dailyCarbByCalories(calories: Double) -> Double {
        return (calories * 0.55) / 4.0 // 55% as a moderate default
    }
    
    static func dailyProteinByWeight(weightKg: Double, goal: WeightGoal) -> Double {
        switch goal {
        case .lose: return weightKg * 2.0 // Higher protein for muscle retention
        case .maintain: return weightKg * 1.8
        case .gain: return weightKg * 2.2 // Higher protein for muscle synthesis
        }
    }
    
    static func dailyFatByCalories(calories: Double) -> Double {
        return (calories * 0.28) / 9.0 // 28% as a moderate default
    }
}

@Model
final class FoodReference {
    var name: String
    var caloriesPerGram: Double
    var carbsPerGram: Double
    var proteinPerGram: Double
    var fatPerGram: Double
    var category: String
    
    init(name: String, caloriesPerGram: Double, carbsPerGram: Double, proteinPerGram: Double, fatPerGram: Double, category: String = "General") {
        self.name = name
        self.caloriesPerGram = caloriesPerGram
        self.carbsPerGram = carbsPerGram
        self.proteinPerGram = proteinPerGram
        self.fatPerGram = fatPerGram
        self.category = category
    }
    
    // Seed list of common foods (Heavily Expanded Database)
    static var defaultFoods: [FoodReference] {
        [
            // 🍎 Fruits
            FoodReference(name: "Apple", caloriesPerGram: 0.52, carbsPerGram: 0.14, proteinPerGram: 0.003, fatPerGram: 0.002, category: "🍎 Fruits"),
            FoodReference(name: "Banana", caloriesPerGram: 0.89, carbsPerGram: 0.23, proteinPerGram: 0.011, fatPerGram: 0.003, category: "🍎 Fruits"),
            FoodReference(name: "Blueberries", caloriesPerGram: 0.57, carbsPerGram: 0.14, proteinPerGram: 0.007, fatPerGram: 0.003, category: "🍎 Fruits"),
            FoodReference(name: "Strawberries", caloriesPerGram: 0.32, carbsPerGram: 0.077, proteinPerGram: 0.007, fatPerGram: 0.003, category: "🍎 Fruits"),
            FoodReference(name: "Mango", caloriesPerGram: 0.60, carbsPerGram: 0.15, proteinPerGram: 0.008, fatPerGram: 0.004, category: "🍎 Fruits"),
            FoodReference(name: "Orange", caloriesPerGram: 0.47, carbsPerGram: 0.12, proteinPerGram: 0.009, fatPerGram: 0.001, category: "🍎 Fruits"),
            FoodReference(name: "Pineapple", caloriesPerGram: 0.50, carbsPerGram: 0.13, proteinPerGram: 0.005, fatPerGram: 0.001, category: "🍎 Fruits"),
            FoodReference(name: "Watermelon", caloriesPerGram: 0.30, carbsPerGram: 0.08, proteinPerGram: 0.006, fatPerGram: 0.002, category: "🍎 Fruits"),
            FoodReference(name: "Grapes", caloriesPerGram: 0.69, carbsPerGram: 0.18, proteinPerGram: 0.007, fatPerGram: 0.002, category: "🍎 Fruits"),
            FoodReference(name: "Peach", caloriesPerGram: 0.39, carbsPerGram: 0.10, proteinPerGram: 0.009, fatPerGram: 0.003, category: "🍎 Fruits"),
            FoodReference(name: "Kiwi", caloriesPerGram: 0.61, carbsPerGram: 0.15, proteinPerGram: 0.011, fatPerGram: 0.005, category: "🍎 Fruits"),
            FoodReference(name: "Raspberries", caloriesPerGram: 0.52, carbsPerGram: 0.12, proteinPerGram: 0.012, fatPerGram: 0.007, category: "🍎 Fruits"),
            FoodReference(name: "Pear", caloriesPerGram: 0.57, carbsPerGram: 0.15, proteinPerGram: 0.004, fatPerGram: 0.001, category: "🍎 Fruits"),
            FoodReference(name: "Grapefruit", caloriesPerGram: 0.42, carbsPerGram: 0.11, proteinPerGram: 0.008, fatPerGram: 0.001, category: "🍎 Fruits"),
            FoodReference(name: "Cherries", caloriesPerGram: 0.50, carbsPerGram: 0.12, proteinPerGram: 0.010, fatPerGram: 0.003, category: "🍎 Fruits"),
            FoodReference(name: "Plum", caloriesPerGram: 0.46, carbsPerGram: 0.11, proteinPerGram: 0.007, fatPerGram: 0.003, category: "🍎 Fruits"),
            
            // 🍗 Proteins
            FoodReference(name: "Chicken Breast", caloriesPerGram: 1.65, carbsPerGram: 0.0, proteinPerGram: 0.31, fatPerGram: 0.036, category: "🍗 Proteins"),
            FoodReference(name: "Salmon (Cooked)", caloriesPerGram: 2.06, carbsPerGram: 0.0, proteinPerGram: 0.22, fatPerGram: 0.12, category: "🍗 Proteins"),
            FoodReference(name: "Ribeye Steak", caloriesPerGram: 2.91, carbsPerGram: 0.0, proteinPerGram: 0.24, fatPerGram: 0.22, category: "🍗 Proteins"),
            FoodReference(name: "Tuna (Canned)", caloriesPerGram: 1.16, carbsPerGram: 0.0, proteinPerGram: 0.26, fatPerGram: 0.01, category: "🍗 Proteins"),
            FoodReference(name: "Whole Egg", caloriesPerGram: 1.55, carbsPerGram: 0.011, proteinPerGram: 0.13, fatPerGram: 0.11, category: "🍗 Proteins"),
            FoodReference(name: "Whey Protein Powder", caloriesPerGram: 4.00, carbsPerGram: 0.10, proteinPerGram: 0.80, fatPerGram: 0.06, category: "🍗 Proteins"),
            FoodReference(name: "Turkey Breast", caloriesPerGram: 1.35, carbsPerGram: 0.0, proteinPerGram: 0.30, fatPerGram: 0.01, category: "🍗 Proteins"),
            FoodReference(name: "Pork Chop (Lean)", caloriesPerGram: 1.96, carbsPerGram: 0.0, proteinPerGram: 0.28, fatPerGram: 0.09, category: "🍗 Proteins"),
            FoodReference(name: "Shrimp (Cooked)", caloriesPerGram: 0.99, carbsPerGram: 0.0, proteinPerGram: 0.24, fatPerGram: 0.003, category: "🍗 Proteins"),
            FoodReference(name: "Tofu (Firm)", caloriesPerGram: 0.76, carbsPerGram: 0.019, proteinPerGram: 0.08, fatPerGram: 0.048, category: "🍗 Proteins"),
            FoodReference(name: "Lean Ground Beef (93/7)", caloriesPerGram: 1.72, carbsPerGram: 0.0, proteinPerGram: 0.26, fatPerGram: 0.07, category: "🍗 Proteins"),
            FoodReference(name: "Cod Fillet", caloriesPerGram: 0.82, carbsPerGram: 0.0, proteinPerGram: 0.18, fatPerGram: 0.007, category: "🍗 Proteins"),
            FoodReference(name: "Tempeh", caloriesPerGram: 1.93, carbsPerGram: 0.09, proteinPerGram: 0.19, fatPerGram: 0.11, category: "🍗 Proteins"),
            FoodReference(name: "Egg Whites", caloriesPerGram: 0.52, carbsPerGram: 0.007, proteinPerGram: 0.11, fatPerGram: 0.002, category: "🍗 Proteins"),
            FoodReference(name: "Duck Breast (No Skin)", caloriesPerGram: 1.40, carbsPerGram: 0.0, proteinPerGram: 0.21, fatPerGram: 0.06, category: "🍗 Proteins"),
            
            // 🍚 Carbs
            FoodReference(name: "White Rice", caloriesPerGram: 1.30, carbsPerGram: 0.28, proteinPerGram: 0.027, fatPerGram: 0.003, category: "🍚 Carbs"),
            FoodReference(name: "Oats", caloriesPerGram: 3.89, carbsPerGram: 0.66, proteinPerGram: 0.17, fatPerGram: 0.07, category: "🍚 Carbs"),
            FoodReference(name: "Sweet Potato", caloriesPerGram: 0.86, carbsPerGram: 0.20, proteinPerGram: 0.016, fatPerGram: 0.001, category: "🍚 Carbs"),
            FoodReference(name: "Quinoa (Cooked)", caloriesPerGram: 1.20, carbsPerGram: 0.21, proteinPerGram: 0.044, fatPerGram: 0.019, category: "🍚 Carbs"),
            FoodReference(name: "Brown Rice (Cooked)", caloriesPerGram: 1.12, carbsPerGram: 0.24, proteinPerGram: 0.026, fatPerGram: 0.009, category: "🍚 Carbs"),
            FoodReference(name: "White Potato (Baked)", caloriesPerGram: 0.93, carbsPerGram: 0.21, proteinPerGram: 0.025, fatPerGram: 0.001, category: "🍚 Carbs"),
            FoodReference(name: "Whole Wheat Pasta", caloriesPerGram: 1.24, carbsPerGram: 0.27, proteinPerGram: 0.053, fatPerGram: 0.005, category: "🍚 Carbs"),
            FoodReference(name: "Couscous", caloriesPerGram: 1.12, carbsPerGram: 0.23, proteinPerGram: 0.038, fatPerGram: 0.002, category: "🍚 Carbs"),
            FoodReference(name: "Sourdough Bread", caloriesPerGram: 2.66, carbsPerGram: 0.52, proteinPerGram: 0.09, fatPerGram: 0.024, category: "🍚 Carbs"),
            FoodReference(name: "Barley", caloriesPerGram: 1.23, carbsPerGram: 0.28, proteinPerGram: 0.023, fatPerGram: 0.004, category: "🍚 Carbs"),
            FoodReference(name: "Rye Bread", caloriesPerGram: 2.59, carbsPerGram: 0.48, proteinPerGram: 0.09, fatPerGram: 0.033, category: "🍚 Carbs"),
            FoodReference(name: "Rice Cakes", caloriesPerGram: 3.87, carbsPerGram: 0.82, proteinPerGram: 0.08, fatPerGram: 0.028, category: "🍚 Carbs"),
            FoodReference(name: "Corn (Sweet)", caloriesPerGram: 0.86, carbsPerGram: 0.19, proteinPerGram: 0.032, fatPerGram: 0.012, category: "🍚 Carbs"),
            FoodReference(name: "Tortilla (Corn)", caloriesPerGram: 2.18, carbsPerGram: 0.45, proteinPerGram: 0.06, fatPerGram: 0.025, category: "🍚 Carbs"),
            
            // 🥜 Fats
            FoodReference(name: "Almonds", caloriesPerGram: 5.79, carbsPerGram: 0.22, proteinPerGram: 0.21, fatPerGram: 0.49, category: "🥜 Fats"),
            FoodReference(name: "Avocado", caloriesPerGram: 1.60, carbsPerGram: 0.09, proteinPerGram: 0.02, fatPerGram: 0.15, category: "🥜 Fats"),
            FoodReference(name: "Peanut Butter", caloriesPerGram: 5.88, carbsPerGram: 0.20, proteinPerGram: 0.25, fatPerGram: 0.50, category: "🥜 Fats"),
            FoodReference(name: "Olive Oil", caloriesPerGram: 8.84, carbsPerGram: 0.0, proteinPerGram: 0.0, fatPerGram: 1.00, category: "🥜 Fats"),
            FoodReference(name: "Walnuts", caloriesPerGram: 6.54, carbsPerGram: 0.14, proteinPerGram: 0.15, fatPerGram: 0.65, category: "🥜 Fats"),
            FoodReference(name: "Cashews", caloriesPerGram: 5.53, carbsPerGram: 0.30, proteinPerGram: 0.18, fatPerGram: 0.44, category: "🥜 Fats"),
            FoodReference(name: "Chia Seeds", caloriesPerGram: 4.86, carbsPerGram: 0.42, proteinPerGram: 0.17, fatPerGram: 0.31, category: "🥜 Fats"),
            FoodReference(name: "Flax Seeds", caloriesPerGram: 5.34, carbsPerGram: 0.29, proteinPerGram: 0.18, fatPerGram: 0.42, category: "🥜 Fats"),
            FoodReference(name: "Pumpkin Seeds", caloriesPerGram: 5.59, carbsPerGram: 0.11, proteinPerGram: 0.30, fatPerGram: 0.49, category: "🥜 Fats"),
            FoodReference(name: "Coconut Oil", caloriesPerGram: 8.62, carbsPerGram: 0.0, proteinPerGram: 0.0, fatPerGram: 1.00, category: "🥜 Fats"),
            FoodReference(name: "Macadamia Nuts", caloriesPerGram: 7.18, carbsPerGram: 0.14, proteinPerGram: 0.08, fatPerGram: 0.76, category: "🥜 Fats"),
            FoodReference(name: "Pecans", caloriesPerGram: 6.91, carbsPerGram: 0.14, proteinPerGram: 0.09, fatPerGram: 0.72, category: "🥜 Fats"),
            FoodReference(name: "Sesame Seeds", caloriesPerGram: 5.73, carbsPerGram: 0.23, proteinPerGram: 0.18, fatPerGram: 0.50, category: "🥜 Fats"),
            FoodReference(name: "Butter (Unsalted)", caloriesPerGram: 7.17, carbsPerGram: 0.0, proteinPerGram: 0.009, fatPerGram: 0.81, category: "🥜 Fats"),
            
            // 🥛 Dairy
            FoodReference(name: "Greek Yogurt", caloriesPerGram: 0.59, carbsPerGram: 0.036, proteinPerGram: 0.10, fatPerGram: 0.004, category: "🥛 Dairy"),
            FoodReference(name: "Cheddar Cheese", caloriesPerGram: 4.02, carbsPerGram: 0.013, proteinPerGram: 0.25, fatPerGram: 0.33, category: "🥛 Dairy"),
            FoodReference(name: "Whole Milk", caloriesPerGram: 0.61, carbsPerGram: 0.048, proteinPerGram: 0.032, fatPerGram: 0.033, category: "🥛 Dairy"),
            FoodReference(name: "Skim Milk", caloriesPerGram: 0.34, carbsPerGram: 0.05, proteinPerGram: 0.034, fatPerGram: 0.001, category: "🥛 Dairy"),
            FoodReference(name: "Cottage Cheese (2%)", caloriesPerGram: 0.81, carbsPerGram: 0.04, proteinPerGram: 0.10, fatPerGram: 0.023, category: "🥛 Dairy"),
            FoodReference(name: "Parmesan Cheese", caloriesPerGram: 4.31, carbsPerGram: 0.04, proteinPerGram: 0.38, fatPerGram: 0.29, category: "🥛 Dairy"),
            FoodReference(name: "Mozzarella (Low Moisture)", caloriesPerGram: 3.00, carbsPerGram: 0.02, proteinPerGram: 0.24, fatPerGram: 0.22, category: "🥛 Dairy"),
            FoodReference(name: "Feta Cheese", caloriesPerGram: 2.64, carbsPerGram: 0.04, proteinPerGram: 0.14, fatPerGram: 0.21, category: "🥛 Dairy"),
            FoodReference(name: "Sour Cream", caloriesPerGram: 1.93, carbsPerGram: 0.03, proteinPerGram: 0.02, fatPerGram: 0.20, category: "🥛 Dairy"),
            FoodReference(name: "Cream Cheese", caloriesPerGram: 3.42, carbsPerGram: 0.04, proteinPerGram: 0.06, fatPerGram: 0.34, category: "🥛 Dairy"),
            FoodReference(name: "Ricotta Cheese", caloriesPerGram: 1.74, carbsPerGram: 0.03, proteinPerGram: 0.11, fatPerGram: 0.13, category: "🥛 Dairy"),
            FoodReference(name: "Heavy Whipping Cream", caloriesPerGram: 3.45, carbsPerGram: 0.027, proteinPerGram: 0.02, fatPerGram: 0.37, category: "🥛 Dairy"),
            
            // 🥦 Veggies
            FoodReference(name: "Broccoli", caloriesPerGram: 0.34, carbsPerGram: 0.07, proteinPerGram: 0.028, fatPerGram: 0.004, category: "🥦 Veggies"),
            FoodReference(name: "Spinach", caloriesPerGram: 0.23, carbsPerGram: 0.036, proteinPerGram: 0.029, fatPerGram: 0.004, category: "🥦 Veggies"),
            FoodReference(name: "Asparagus", caloriesPerGram: 0.20, carbsPerGram: 0.039, proteinPerGram: 0.022, fatPerGram: 0.001, category: "🥦 Veggies"),
            FoodReference(name: "Brussels Sprouts", caloriesPerGram: 0.43, carbsPerGram: 0.09, proteinPerGram: 0.034, fatPerGram: 0.003, category: "🥦 Veggies"),
            FoodReference(name: "Cauliflower", caloriesPerGram: 0.25, carbsPerGram: 0.05, proteinPerGram: 0.019, fatPerGram: 0.003, category: "🥦 Veggies"),
            FoodReference(name: "Zucchini", caloriesPerGram: 0.17, carbsPerGram: 0.031, proteinPerGram: 0.012, fatPerGram: 0.003, category: "🥦 Veggies"),
            FoodReference(name: "Eggplant", caloriesPerGram: 0.25, carbsPerGram: 0.06, proteinPerGram: 0.01, fatPerGram: 0.002, category: "🥦 Veggies"),
            FoodReference(name: "Cucumber", caloriesPerGram: 0.15, carbsPerGram: 0.036, proteinPerGram: 0.007, fatPerGram: 0.001, category: "🥦 Veggies"),
            FoodReference(name: "Bell Pepper (Red)", caloriesPerGram: 0.31, carbsPerGram: 0.06, proteinPerGram: 0.01, fatPerGram: 0.003, category: "🥦 Veggies"),
            FoodReference(name: "Carrot", caloriesPerGram: 0.41, carbsPerGram: 0.10, proteinPerGram: 0.009, fatPerGram: 0.002, category: "🥦 Veggies"),
            FoodReference(name: "Celery", caloriesPerGram: 0.16, carbsPerGram: 0.03, proteinPerGram: 0.007, fatPerGram: 0.002, category: "🥦 Veggies"),
            FoodReference(name: "Green Beans", caloriesPerGram: 0.31, carbsPerGram: 0.07, proteinPerGram: 0.018, fatPerGram: 0.002, category: "🥦 Veggies"),
            FoodReference(name: "Kale", caloriesPerGram: 0.49, carbsPerGram: 0.09, proteinPerGram: 0.043, fatPerGram: 0.009, category: "🥦 Veggies"),
            FoodReference(name: "Mushrooms (White)", caloriesPerGram: 0.22, carbsPerGram: 0.033, proteinPerGram: 0.031, fatPerGram: 0.003, category: "🥦 Veggies"),
            FoodReference(name: "Onion (Yellow)", caloriesPerGram: 0.40, carbsPerGram: 0.09, proteinPerGram: 0.011, fatPerGram: 0.001, category: "🥦 Veggies"),
            FoodReference(name: "Garlic", caloriesPerGram: 1.49, carbsPerGram: 0.33, proteinPerGram: 0.064, fatPerGram: 0.005, category: "🥦 Veggies")
        ]
    }
}

@Model
final class LogEntry {
    var id: UUID
    var timestamp: Date
    var foodName: String
    var grams: Double
    var calories: Double
    var carbs: Double
    var protein: Double
    var fat: Double
    var xpEarned: Int
    
    // Relationship to UserProfile
    var userProfile: UserProfile? // Logs can be tied to a specific user
    
    init(id: UUID = UUID(), timestamp: Date = Date(), foodName: String, grams: Double, calories: Double, carbs: Double, protein: Double, fat: Double, xpEarned: Int, userProfile: UserProfile? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.foodName = foodName
        self.grams = grams
        self.calories = calories
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.xpEarned = xpEarned
        self.userProfile = userProfile
    }
}
