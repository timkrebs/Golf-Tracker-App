//
//  AuthenticationCoordinator.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import SwiftUI

struct AuthenticationCoordinator: View {
    @StateObject private var authService: SupabaseAuthService
    @StateObject private var dataService: SupabaseDataService
    
    init() {
        // Create a single authService instance that will be shared
        let authServiceInstance = SupabaseAuthService()
        _authService = StateObject(wrappedValue: authServiceInstance)
        _dataService = StateObject(wrappedValue: SupabaseDataService(authService: authServiceInstance))
    }
    
    var body: some View {
        Group {
            if authService.session != nil {
                DashboardView()
                    .environmentObject(authService)
                    .environmentObject(dataService)
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
        .onChange(of: authService.session) { _, newValue in
            Task {
                if newValue != nil {
                    await dataService.fetchDashboardData()
                } else {
                    dataService.clearData()
                }
            }
        }
    }
}

#Preview {
    AuthenticationCoordinator()
} 
