//
//  UserProfileSetupView.swift
//  CaloBite
//
//  Created by Giulliano Suarez on 6/8/26.
//

import SwiftUI
import SwiftData

struct UserProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Local @State properties for form inputs
    @State private var name: String
    @State private var age: Int
    @State private var heightCm: Double
    @State private var currentWeightKg: Double
    @State private var gender: Gender
    @State private var activityLevel: ActivityLevel
    @State private var weightGoal: WeightGoal

    // The userProfile to be edited, passed as a regular optional variable.
    // If it's nil, we are creating a new profile. No @Bindable needed here.
    var userProfileToEdit: UserProfile?

    // Custom initializer to handle both creation (no userProfileToEdit) and editing
    init(userProfileToEdit: UserProfile? = nil) {
        self.userProfileToEdit = userProfileToEdit
        // Initialize @State properties with existing profile data or default values
        _name = State(initialValue: userProfileToEdit?.name ?? "")
        _age = State(initialValue: userProfileToEdit?.age ?? 25)
        _heightCm = State(initialValue: userProfileToEdit?.heightCm ?? 170)
        _currentWeightKg = State(initialValue: userProfileToEdit?.currentWeightKg ?? 70)
        _gender = State(initialValue: userProfileToEdit?.gender ?? .male)
        _activityLevel = State(initialValue: userProfileToEdit?.activityLevel ?? .moderatelyActive)
        _weightGoal = State(initialValue: userProfileToEdit?.weightGoal ?? .maintain)
    }

    var isEditMode: Bool { userProfileToEdit != nil }

    // Computed property to check if the name is valid for saving
    var isSaveButtonDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || age < 15 || heightCm < 100 || currentWeightKg < 30
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Details") {
                    TextField("Name", text: $name)
                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    Stepper("Age: \(age) years", value: $age, in: 15...100)
                    Stepper("Height: \(Int(heightCm)) cm", value: $heightCm, in: 100...250)
                    Stepper("Weight: \(Int(currentWeightKg)) kg", value: $currentWeightKg, in: 30...200)
                }

                Section("Fitness Goals") {
                    Picker("Activity Level", selection: $activityLevel) {
                        ForEach(ActivityLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    Picker("Weight Goal", selection: $weightGoal) {
                        ForEach(WeightGoal.allCases) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                }

                Button(isEditMode ? "Save Profile" : "Create Profile") {
                    if let existingProfile = userProfileToEdit {
                        // Update existing profile properties
                        existingProfile.name = name
                        existingProfile.age = age
                        existingProfile.heightCm = heightCm
                        existingProfile.currentWeightKg = currentWeightKg
                        existingProfile.gender = gender
                        existingProfile.activityLevel = activityLevel
                        existingProfile.weightGoal = weightGoal
                        
                        // Recalculate default goals upon update, mirroring the logic from UserProfile's init
                        let calculatedBMR: Double
                        switch existingProfile.gender {
                        case .male:
                            calculatedBMR = (10 * existingProfile.currentWeightKg) + (6.25 * existingProfile.heightCm) - (5 * Double(existingProfile.age)) + 5
                        case .female:
                            calculatedBMR = (10 * existingProfile.currentWeightKg) + (6.25 * existingProfile.heightCm) - (5 * Double(existingProfile.age)) - 161
                        }
                        
                        let calculatedTDEE = calculatedBMR * existingProfile.activityLevel.multiplier
                        let initialDailyCalories = calculatedTDEE + existingProfile.weightGoal.calorieAdjustment
                        
                        existingProfile.dailyCalorieGoal = initialDailyCalories
                        existingProfile.dailyCarbGoal = UserProfile.dailyCarbByCalories(calories: initialDailyCalories)
                        existingProfile.dailyProteinGoal = UserProfile.dailyProteinByWeight(weightKg: existingProfile.currentWeightKg, goal: existingProfile.weightGoal)
                        existingProfile.dailyFatGoal = UserProfile.dailyFatByCalories(calories: initialDailyCalories)
                        
                    } else {
                        // Create a new profile
                        let newProfile = UserProfile(
                            name: name,
                            age: age,
                            heightCm: heightCm,
                            currentWeightKg: currentWeightKg,
                            gender: gender,
                            activityLevel: activityLevel,
                            weightGoal: weightGoal
                        )
                        modelContext.insert(newProfile)
                    }

                    do {
                        try modelContext.save()
                        dismiss() // Dismiss the sheet upon successful save/creation
                    } catch {
                        print("Failed to save profile: \(error)")
                        // In a real app, you might present an alert here
                    }
                }
                .disabled(isSaveButtonDisabled)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .padding(.vertical)
                .tint(.purple) // Apply the app's theme color
            }
            .navigationTitle(isEditMode ? "Edit Profile" : "Create Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Only show cancel button in edit mode
                    if isEditMode {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
