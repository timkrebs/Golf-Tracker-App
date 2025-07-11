//
//  SplashScreenView.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var showMainApp = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.8, blue: 0.4),
                    Color(red: 0.15, green: 0.7, blue: 0.35),
                    Color(red: 0.1, green: 0.6, blue: 0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)
            
            // Subtle pattern overlay
            VStack {
                ForEach(0..<8, id: \.self) { _ in
                    HStack {
                        ForEach(0..<6, id: \.self) { _ in
                            Circle()
                                .fill(Color.white.opacity(0.03))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .opacity(backgroundOpacity)
            
            VStack(spacing: 30) {
                Spacer()
                
                // Main Logo Section
                VStack(spacing: 20) {
                    // Golf ball and flag icon
                    ZStack {
                        // Outer glow circle
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 140, height: 140)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                        
                        // Main circle
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 120, height: 120)
                        
                        // Golf icon
                        ZStack {
                            // Flag pole
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 2, height: 30)
                                .offset(x: -8, y: 0)
                            
                            // Flag
                            Path { path in
                                path.move(to: CGPoint(x: -6, y: -15))
                                path.addLine(to: CGPoint(x: 12, y: -10))
                                path.addLine(to: CGPoint(x: 12, y: 0))
                                path.addLine(to: CGPoint(x: -6, y: -5))
                                path.closeSubpath()
                            }
                            .fill(Color.white)
                            
                            // Golf ball
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .offset(x: -12, y: 12)
                            
                            // Small dimples on golf ball
                            VStack(spacing: 1) {
                                HStack(spacing: 1) {
                                    Circle().fill(Color.green.opacity(0.3)).frame(width: 1, height: 1)
                                    Circle().fill(Color.green.opacity(0.3)).frame(width: 1, height: 1)
                                }
                                Circle().fill(Color.green.opacity(0.3)).frame(width: 1, height: 1)
                            }
                            .offset(x: -12, y: 12)
                        }
                        .font(.system(size: 24, weight: .bold))
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .rotation3DEffect(
                        .degrees(isAnimating ? 5 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    
                    // App Title
                    VStack(spacing: 8) {
                        Text("GolfTracker")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(textOpacity)
                        
                        Text("Dein Golf-Begleiter")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(textOpacity)
                    }
                }
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 16) {
                    // Custom golf-themed loading indicator
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isAnimating ? 1.0 : 0.5)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                    .opacity(textOpacity)
                    
                    Text("Lade Deine Golf-Daten...")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(textOpacity)
                }
                .padding(.bottom, 20)
                
                // Tap to skip hint
                Text("Tippe zum Überspringen")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .opacity(textOpacity)
                    .padding(.bottom, 40)
            }
        }
        .onTapGesture {
            // Allow user to skip splash screen
            withAnimation(.easeInOut(duration: 0.3)) {
                showMainApp = true
            }
        }
        .onAppear {
            startAnimations()
            
            // Auto-transition to main app after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showMainApp = true
                }
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            AuthenticationCoordinator()
        }
    }
    
    private func startAnimations() {
        // Background fade in
        withAnimation(.easeIn(duration: 0.5)) {
            backgroundOpacity = 1.0
        }
        
        // Logo scale and fade in
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0).delay(0.3)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Text fade in
        withAnimation(.easeInOut(duration: 0.6).delay(0.6)) {
            textOpacity = 1.0
        }
        
        // Start continuous animations
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.0)) {
            isAnimating = true
        }
    }
}

#Preview {
    SplashScreenView()
} 