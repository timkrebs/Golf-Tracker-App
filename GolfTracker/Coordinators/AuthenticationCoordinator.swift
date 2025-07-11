//
//  AuthenticationCoordinator.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import SwiftUI

struct AuthenticationCoordinator: View {
    @StateObject private var authService = SupabaseAuthService()
    @StateObject private var dataService: SupabaseDataService
    
    init() {
        let auth = SupabaseAuthService()
        _authService = StateObject(wrappedValue: auth)
        _dataService = StateObject(wrappedValue: SupabaseDataService(authService: auth))
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
        .onChange(of: authService.session) { oldValue, newValue in
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