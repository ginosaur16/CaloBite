//
//  SplashView.swift
//  CaloBite
//
//  Created by Giulliano Suarez on 6/8/26.
//

import SwiftUI

struct SplashView: View {
    @Binding var isShowingSplash: Bool
    @State private var splashScale: CGFloat = 0.85
    @State private var splashOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.purple.opacity(0.25), .indigo.opacity(0.20), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
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
                        .foregroundStyle(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                    
                    Text("FUEL YOUR QUEST")
                        .font(.system(.caption, design: .monospaced))
                        .bold()
                        .tracking(4)
                        .foregroundStyle(.secondary)
                }
                .opacity(splashOpacity)
                
                Spacer()
                
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
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                splashScale = 1.0
                splashOpacity = 1.0
            }
            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                withAnimation(.easeInOut(duration: 0.6)) {
                    isShowingSplash = false
                }
            }
        }
    }
}
