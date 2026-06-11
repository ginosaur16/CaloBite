//
//  AddFoodLogSheet.swift
//  CaloBite
//
//  Created by Giulliano Suarez on 6/8/26.
//

import SwiftUI

struct AddFoodLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: CaloBiteViewModel
    @State private var weightGrams: Double = 100.0
    @State private var isCustomFoodSheetPresented = false
    
    let categories = ["All", "🍎 Fruits", "🍗 Proteins", "🍚 Carbs", "🥜 Fats", "🥛 Dairy", "🥦 Veggies", "🛠️ Custom"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.purple.opacity(0.12), .indigo.opacity(0.08), Color(.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    SearchBar(text: $vm.searchQuery)
                        .padding([.horizontal, .top])
                    
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
                                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.purple)
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
                    .scrollContentBackground(.hidden)
                    
                    if let selected = vm.selectedFood {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Calculating Details:")
                                    .font(.caption)
                                    .bold()
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(selected.name).bold()
                            }
                            
                            VStack {
                                HStack {
                                    Text("Portion Size").bold()
                                    Spacer()
                                    Text("\(Int(weightGrams)) grams")
                                        .font(.title3)
                                        .bold()
                                        .foregroundStyle(.purple)
                                }
                                Slider(value: $weightGrams, in: 10...500, step: 5).tint(.purple)
                            }
                            
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
                    Button("Close") { dismiss() }
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
    
    @State private var customName: String = ""
    @State private var inputCalories: Double = 150.0
    @State private var inputCarbs: Double = 15.0
    @State private var inputProtein: Double = 10.0
    @State private var inputFat: Double = 5.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.purple.opacity(0.12), .indigo.opacity(0.08), Color(.systemBackground)],
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
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Food Name")
                                    .bold()
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("e.g. Homemade Meatballs", text: $customName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            Divider()
                            
                            macroCustomInputRow(title: "Calories (per 100g)", value: $inputCalories, bounds: 0...900, step: 5, unit: "kcal", tint: .orange)
                            macroCustomInputRow(title: "Carbohydrates (per 100g)", value: $inputCarbs, bounds: 0...100, step: 1, unit: "g", tint: .green)
                            macroCustomInputRow(title: "Protein (per 100g)", value: $inputProtein, bounds: 0...100, step: 1, unit: "g", tint: .blue)
                            macroCustomInputRow(title: "Fats (per 100g)", value: $inputFat, bounds: 0...100, step: 1, unit: "g", tint: .yellow)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .padding(.horizontal)
                        
                        Button {
                            guard !customName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            
                            let newFood = vm.addCustomFood(
                                name: customName,
                                calories100g: inputCalories,
                                carbs100g: inputCarbs,
                                protein100g: inputProtein,
                                fat100g: inputFat
                            )
                            
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
                    Button("Cancel") { dismiss() }
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
            Slider(value: value, in: bounds, step: step).tint(tint)
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
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
    }
}
