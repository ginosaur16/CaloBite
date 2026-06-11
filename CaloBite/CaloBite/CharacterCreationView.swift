//
//  CharacterCreationView.swift
//  CaloBite
//
//  Created by Giulliano Suarez on 6/8/26.
//

import SwiftUI

struct CharacterCreationView: View {
    @Binding var username: String
    @Binding var userAvatar: String
    @Binding var hasCompletedProfileSetup: Bool
    
    // Solves compiler type-checking by caching the validation check
    private var isNameEmpty: Bool {
        username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.purple.opacity(0.20), .indigo.opacity(0.12), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Text("AVATAR FORGE")
                            .font(.system(.title, design: .monospaced))
                            .bold()
                            .tracking(4)
                            .foregroundStyle(.purple)
                        Text("Create your warrior profile to begin the journey")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.purple.opacity(0.3), .indigo.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 120, height: 120)
                            .shadow(color: .purple.opacity(0.3), radius: 10)
                        Text(userAvatar)
                            .font(.system(size: 64))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CHOOSE CLASS EMBLEM")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                        
                        let avatarOptions = ["🛡️", "🧙‍♂️", "🗡️", "🏹", "🐉", "🦄", "🦁", "🦊", "🐼", "🦅"]
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
                            ForEach(avatarOptions, id: \.self) { icon in
                                Button {
                                    withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.7)) {
                                        userAvatar = icon
                                    }
                                } label: {
                                    Text(icon)
                                        .font(.system(size: 32))
                                        .padding(10)
                                        .background(
                                            Circle()
                                                .fill(userAvatar == icon ? Color.purple.opacity(0.2) : Color.black.opacity(0.04))
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(userAvatar == icon ? Color.purple : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HERO CODENAME")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.purple)
                            TextField("Enter warrior name...", text: $username)
                                .font(.body)
                                .bold()
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground).opacity(0.6)))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.3), lineWidth: 1))
                    }
                    .padding(.horizontal)
                    
                    Button {
                        let validatedName = username.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !validatedName.isEmpty {
                            username = validatedName
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                                hasCompletedProfileSetup = true
                            }
                        }
                    } label: {
                        HStack {
                            Text("COMMENCE QUEST")
                            Image(systemName: "arrow.right")
                        }
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            Group {
                                if isNameEmpty {
                                    Color.gray
                                } else {
                                    LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing)
                                }
                            }
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isNameEmpty)
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
        }
    }
}
