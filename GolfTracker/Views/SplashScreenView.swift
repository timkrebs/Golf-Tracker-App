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
                    // Golf Logo - consistent with Dashboard
                    ZStack {
                        // Outer glow circle with improved animation
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ]),
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(isAnimating ? 1.05 : 1.0)
                        
                        // Main logo background - same as Dashboard but larger
                        Circle()
                            .fill(Color.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                        
                        // Golf Flag Icon - exactly like Dashboard
                        Image(systemName: "flag.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .rotation3DEffect(
                        .degrees(isAnimating ? 3 : 0),
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
                
                // Enhanced Loading indicator
                VStack(spacing: 16) {
                    // Improved golf-themed loading indicator
                    HStack(spacing: 6) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                                .scaleEffect(isAnimating ? 1.2 : 0.8)
                                .opacity(isAnimating ? 1.0 : 0.6)
                                .animation(
                                    Animation.easeInOut(duration: 0.8)
                                        .repeatForever()
                                        .delay(Double(index) * 0.15),
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
        // Background fade in with smoother timing
        withAnimation(.easeIn(duration: 0.4)) {
            backgroundOpacity = 1.0
        }
        
        // Logo scale and fade in with improved spring animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Text fade in with better timing
        withAnimation(.easeInOut(duration: 0.5).delay(0.5)) {
            textOpacity = 1.0
        }
        
        // Start continuous animations with smoother cycle
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.8)) {
            isAnimating = true
        }
    }
}

#Preview {
    SplashScreenView()
} 
