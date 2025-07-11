//
//  AuthServiceTests.swift
//  GolfTrackerTests
//
//  Created by Tim Krebs on 7/11/25.
//

import Testing
import Foundation
@testable import GolfTracker

@MainActor
struct AuthServiceTests {
    
    // MARK: - Initialization Tests
    
    @Test func authServiceInitialization() async throws {
        // Given & When
        let authService = MockSupabaseAuthService()
        
        // Then
        #expect(authService.session == nil)
        #expect(authService.isLoading == false)
        #expect(authService.errorMessage == nil)
    }
    
    @Test func authServiceInitializationWithSession() async throws {
        // Given & When
        let authService = MockSupabaseAuthService(withSession: true)
        
        // Then
        #expect(authService.session != nil)
        #expect(authService.session?.user.id == "test-user-123")
        #expect(authService.session?.user.email == "test@example.com")
    }
    
    // MARK: - Sign Up Tests
    
    @Test func successfulSignUp() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        authService.shouldSucceedSignUp = true
        
        // When
        let result = await authService.signUp(
            email: "newuser@example.com",
            password: "password123",
            name: "New User"
        )
        
        // Then
        #expect(result == true)
        #expect(authService.session != nil)
        #expect(authService.session?.user.email == "newuser@example.com")
        #expect(authService.session?.user.name == "New User")
        #expect(authService.isLoading == false)
        #expect(authService.errorMessage == nil)
    }
    
    @Test func failedSignUp() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        authService.shouldSucceedSignUp = false
        
        // When
        let result = await authService.signUp(
            email: "invalid@example.com",
            password: "weak",
            name: "User"
        )
        
        // Then
        #expect(result == false)
        #expect(authService.session == nil)
        #expect(authService.isLoading == false)
        #expect(authService.errorMessage == "Sign up failed")
    }
    
    @Test func signUpWithNetworkDelay() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        authService.shouldSucceedSignUp = true
        authService.simulateNetworkDelay = true
        
        let startTime = Date()
        
        // When
        let result = await authService.signUp(
            email: "test@example.com",
            password: "password123",
            name: "Test User"
        )
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        #expect(result == true)
        #expect(duration >= 0.5) // Should take at least 0.5 seconds due to simulated delay
        #expect(authService.isLoading == false)
    }
    
    // MARK: - Sign In Tests
    
    @Test func successfulSignIn() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        authService.shouldSucceedSignIn = true
        
        // When
        let result = await authService.signIn(
            email: "user@example.com",
            password: "password123"
        )
        
        // Then
        #expect(result == true)
        #expect(authService.session != nil)
        #expect(authService.session?.user.email == "user@example.com")
        #expect(authService.isLoading == false)
        #expect(authService.errorMessage == nil)
    }
    
    @Test func failedSignIn() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        authService.shouldSucceedSignIn = false
        
        // When
        let result = await authService.signIn(
            email: "wrong@example.com",
            password: "wrongpassword"
        )
        
        // Then
        #expect(result == false)
        #expect(authService.session == nil)
        #expect(authService.isLoading == false)
        #expect(authService.errorMessage == "Sign in failed")
    }
    
    @Test func signInWithExistingSession() async throws {
        // Given
        let authService = MockSupabaseAuthService(withSession: true)
        let originalSession = authService.session
        
        // When
        let result = await authService.signIn(
            email: "newuser@example.com",
            password: "password123"
        )
        
        // Then
        #expect(result == true)
        #expect(authService.session != nil)
        #expect(authService.session?.user.email == "newuser@example.com") // Should be new session
        #expect(authService.session != originalSession) // Should be different session
    }
    
    // MARK: - Sign Out Tests
    
    @Test func successfulSignOut() async throws {
        // Given
        let authService = MockSupabaseAuthService(withSession: true)
        authService.shouldSucceedSignOut = true
        
        // Verify initial state
        #expect(authService.session != nil)
        
        // When
        await authService.signOut()
        
        // Then
        #expect(authService.session == nil)
        #expect(authService.errorMessage == nil)
    }
    
    @Test func failedSignOut() async throws {
        // Given
        let authService = MockSupabaseAuthService(withSession: true)
        authService.shouldSucceedSignOut = false
        
        // Verify initial state
        #expect(authService.session != nil)
        
        // When
        await authService.signOut()
        
        // Then
        #expect(authService.session != nil) // Should still have session
        #expect(authService.errorMessage == "Sign out failed")
    }
    
    @Test func signOutWithoutSession() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        authService.shouldSucceedSignOut = true
        
        // Verify initial state
        #expect(authService.session == nil)
        
        // When
        await authService.signOut()
        
        // Then
        #expect(authService.session == nil)
        #expect(authService.errorMessage == nil)
    }
    
    // MARK: - Session Management Tests
    
    @Test func checkSessionWithExistingSession() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        let testUser = TestDataFactory.createTestUser()
        let testSession = TestDataFactory.createTestAuthSession(user: testUser)
        authService.setMockSession(testSession)
        
        // When
        await authService.checkSession()
        
        // Then
        #expect(authService.session != nil)
        #expect(authService.session?.user.id == testUser.id)
        #expect(authService.session?.accessToken == testSession.accessToken)
    }
    
    @Test func checkSessionWithoutExistingSession() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        authService.setMockSession(nil)
        
        // When
        await authService.checkSession()
        
        // Then
        #expect(authService.session == nil)
    }
    
    @Test func setMockSession() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        let testUser = TestDataFactory.createTestUser()
        let testSession = TestDataFactory.createTestAuthSession(user: testUser)
        
        // When
        authService.setMockSession(testSession)
        
        // Then
        #expect(authService.session == testSession)
    }
    
    @Test func clearMockSession() async throws {
        // Given
        let authService = MockSupabaseAuthService(withSession: true)
        #expect(authService.session != nil)
        
        // When
        authService.setMockSession(nil)
        
        // Then
        #expect(authService.session == nil)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func simulateCustomError() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        let errorMessage = "Custom authentication error"
        
        // When
        authService.simulateError(errorMessage)
        
        // Then
        #expect(authService.errorMessage == errorMessage)
    }
    
    @Test func errorMessageClearing() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        authService.simulateError("Initial error")
        #expect(authService.errorMessage != nil)
        
        // When - Successful sign in should clear error
        authService.shouldSucceedSignIn = true
        let result = await authService.signIn(email: "test@example.com", password: "password")
        
        // Then
        #expect(result == true)
        #expect(authService.errorMessage == nil) // Error should be cleared
    }
    
    @Test func loadingStateManagement() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        authService.simulateNetworkDelay = true
        
        // Start async sign in
        let signInTask = Task {
            return await authService.signIn(email: "test@example.com", password: "password")
        }
        
        // Immediately check loading state
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        #expect(authService.isLoading == true)
        
        // Wait for completion
        let result = await signInTask.value
        #expect(result == true)
        #expect(authService.isLoading == false)
    }
    
    // MARK: - Authentication Flow Tests
    
    @Test func completeAuthenticationFlow() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        
        // Step 1: Initial state
        #expect(authService.session == nil)
        
        // Step 2: Sign up
        let signUpResult = await authService.signUp(
            email: "newuser@example.com",
            password: "password123",
            name: "New User"
        )
        #expect(signUpResult == true)
        #expect(authService.session != nil)
        
        // Step 3: Sign out
        await authService.signOut()
        #expect(authService.session == nil)
        
        // Step 4: Sign in
        let signInResult = await authService.signIn(
            email: "newuser@example.com",
            password: "password123"
        )
        #expect(signInResult == true)
        #expect(authService.session != nil)
        
        // Step 5: Final sign out
        await authService.signOut()
        #expect(authService.session == nil)
    }
    
    @Test func sessionPersistence() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        
        // Sign in
        let signInResult = await authService.signIn(
            email: "test@example.com",
            password: "password123"
        )
        #expect(signInResult == true)
        
        let originalSession = authService.session
        #expect(originalSession != nil)
        
        // Check session (simulates app restart)
        await authService.checkSession()
        
        // Session should persist
        #expect(authService.session != nil)
        #expect(authService.session?.user.id == originalSession?.user.id)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test func signUpWithEmptyCredentials() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        
        // When
        let result = await authService.signUp(
            email: "",
            password: "",
            name: ""
        )
        
        // Then - Mock service doesn't validate, but should still handle gracefully
        #expect(authService.session?.user.email == "")
        #expect(authService.session?.user.name == "")
    }
    
    @Test func signInWithEmptyCredentials() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        
        // When
        let result = await authService.signIn(
            email: "",
            password: ""
        )
        
        // Then
        #expect(authService.session?.user.email == "")
    }
    
    @Test func multipleSimultaneousRequests() async throws {
        // Given
        let authService = MockSupabaseAuthService()
        authService.simulateNetworkDelay = true
        
        // When - Start multiple sign in requests simultaneously
        async let result1 = authService.signIn(email: "user1@example.com", password: "password")
        async let result2 = authService.signIn(email: "user2@example.com", password: "password")
        async let result3 = authService.signIn(email: "user3@example.com", password: "password")
        
        let results = await [result1, result2, result3]
        
        // Then - All should succeed, last one wins
        #expect(results.allSatisfy { $0 == true })
        #expect(authService.session?.user.email == "user3@example.com") // Last request wins
        #expect(authService.isLoading == false)
    }
} 