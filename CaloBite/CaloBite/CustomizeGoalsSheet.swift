//
//  CustomizeGoalsSheet.swift
//  CaloBite
//
//  Created by Giulliano Suarez on 6/8/26.
//

import SwiftUI

struct CustomizeGoalsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: CaloBiteViewModel
    
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
                            goalTuningSlider(title: "Calories", value: $vm.dailyCalorieGoal, bounds: 1000...5000, step: 50, unit: "kcal", tint: .orange)
                            goalTuningSlider(title: "Carbs Target", value: $vm.dailyCarbGoal, bounds: 50...400, step: 5, unit: "g", tint: .green)
                            goalTuningSlider(title: "Protein Target", value: $vm.dailyProteinGoal, bounds: 40...300, step: 5, unit: "g", tint: .blue)
                            goalTuningSlider(title: "Fat Target", value: $vm.dailyFatGoal, bounds: 20...150, step: 5, unit: "g", tint: .yellow)
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
                    Button("Close") { dismiss() }
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
            Slider(value: value, in: bounds, step: step).tint(tint)
        }
        .padding(.vertical, 4)
    }
}
