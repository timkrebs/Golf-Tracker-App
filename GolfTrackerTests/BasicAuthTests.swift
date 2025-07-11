//
//  BasicAuthTests.swift
//  GolfTrackerTests
//
//  Created by Tim Krebs on 7/11/25.
//

import XCTest
@testable import GolfTracker

@MainActor
final class BasicAuthTests: XCTestCase {
    
    var mockAuthService: MockSupabaseAuthService!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockSupabaseAuthService()
    }
    
    override func tearDown() {
        mockAuthService = nil
        super.tearDown()
    }
    
    // MARK: - Sign Up Tests
    
    func testSuccessfulSignUp() async {
        // Given
        mockAuthService.shouldSucceedSignUp = true
        let email = "test@example.com"
        let password = "password123"
        let name = "Test User"
        
        // When
        let result = await mockAuthService.signUp(email: email, password: password, name: name)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertNotNil(mockAuthService.session)
        XCTAssertEqual(mockAuthService.session?.user.email, email)
        XCTAssertEqual(mockAuthService.session?.user.name, name)
        XCTAssertNil(mockAuthService.errorMessage)
        XCTAssertFalse(mockAuthService.isLoading)
    }
    
    func testFailedSignUp() async {
        // Given
        mockAuthService.shouldSucceedSignUp = false
        let email = "test@example.com"
        let password = "password123"
        let name = "Test User"
        
        // When
        let result = await mockAuthService.signUp(email: email, password: password, name: name)
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNil(mockAuthService.session)
        XCTAssertNotNil(mockAuthService.errorMessage)
        XCTAssertEqual(mockAuthService.errorMessage, "Sign up failed")
        XCTAssertFalse(mockAuthService.isLoading)
    }
    
    // MARK: - Sign In Tests
    
    func testSuccessfulSignIn() async {
        // Given
        mockAuthService.shouldSucceedSignIn = true
        let email = "existing@example.com"
        let password = "password123"
        
        // When
        let result = await mockAuthService.signIn(email: email, password: password)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertNotNil(mockAuthService.session)
        XCTAssertEqual(mockAuthService.session?.user.email, email)
        XCTAssertNil(mockAuthService.errorMessage)
        XCTAssertFalse(mockAuthService.isLoading)
    }
    
    func testFailedSignIn() async {
        // Given
        mockAuthService.shouldSucceedSignIn = false
        let email = "wrong@example.com"
        let password = "wrongpassword"
        
        // When
        let result = await mockAuthService.signIn(email: email, password: password)
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNil(mockAuthService.session)
        XCTAssertNotNil(mockAuthService.errorMessage)
        XCTAssertEqual(mockAuthService.errorMessage, "Sign in failed")
        XCTAssertFalse(mockAuthService.isLoading)
    }
    
    // MARK: - Sign Out Tests
    
    func testSuccessfulSignOut() async {
        // Given - start with a signed in user
        mockAuthService.shouldSucceedSignIn = true
        _ = await mockAuthService.signIn(email: "test@example.com", password: "password")
        XCTAssertNotNil(mockAuthService.session) // Verify we're signed in
        
        mockAuthService.shouldSucceedSignOut = true
        
        // When
        await mockAuthService.signOut()
        
        // Then
        XCTAssertNil(mockAuthService.session)
        XCTAssertNil(mockAuthService.errorMessage)
    }
    
    func testFailedSignOut() async {
        // Given - start with a signed in user
        mockAuthService.shouldSucceedSignIn = true
        _ = await mockAuthService.signIn(email: "test@example.com", password: "password")
        let originalSession = mockAuthService.session
        XCTAssertNotNil(originalSession)
        
        mockAuthService.shouldSucceedSignOut = false
        
        // When
        await mockAuthService.signOut()
        
        // Then
        XCTAssertNotNil(mockAuthService.session) // Session should remain
        XCTAssertEqual(mockAuthService.session?.user.id, originalSession?.user.id)
        XCTAssertNotNil(mockAuthService.errorMessage)
        XCTAssertEqual(mockAuthService.errorMessage, "Sign out failed")
    }
    
    // MARK: - Session Management Tests
    
    func testCheckSessionWithExistingSession() async {
        // Given
        let testUser = TestDataFactory.createTestUser()
        let testSession = TestDataFactory.createTestAuthSession(user: testUser)
        mockAuthService.setMockSession(testSession)
        
        // When
        await mockAuthService.checkSession()
        
        // Then
        XCTAssertNotNil(mockAuthService.session)
        XCTAssertEqual(mockAuthService.session?.user.id, testUser.id)
        XCTAssertEqual(mockAuthService.session?.accessToken, testSession.accessToken)
    }
    
    func testCheckSessionWithNoSession() async {
        // Given
        mockAuthService.setMockSession(nil)
        
        // When
        await mockAuthService.checkSession()
        
        // Then
        XCTAssertNil(mockAuthService.session)
    }
    
    // MARK: - Authentication State Tests
    
    func testAuthenticationStateTransitions() async {
        // Start unauthenticated
        XCTAssertNil(mockAuthService.session)
        
        // Sign up
        mockAuthService.shouldSucceedSignUp = true
        let signUpResult = await mockAuthService.signUp(
            email: "newuser@example.com",
            password: "password123",
            name: "New User"
        )
        XCTAssertTrue(signUpResult)
        XCTAssertNotNil(mockAuthService.session)
        
        // Sign out
        mockAuthService.shouldSucceedSignOut = true
        await mockAuthService.signOut()
        XCTAssertNil(mockAuthService.session)
        
        // Sign in with existing account
        mockAuthService.shouldSucceedSignIn = true
        let signInResult = await mockAuthService.signIn(
            email: "existing@example.com",
            password: "password123"
        )
        XCTAssertTrue(signInResult)
        XCTAssertNotNil(mockAuthService.session)
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStatesDuringSignUp() async {
        // Given
        mockAuthService.simulateNetworkDelay = true
        mockAuthService.shouldSucceedSignUp = true
        
        // When - start sign up
        let signUpTask = Task {
            await mockAuthService.signUp(
                email: "test@example.com",
                password: "password123",
                name: "Test User"
            )
        }
        
        // Then - should be loading initially
        // Note: In a real test, you might need to check this immediately after starting the task
        // For this mock, we'll verify the final state
        let result = await signUpTask.value
        
        XCTAssertTrue(result)
        XCTAssertFalse(mockAuthService.isLoading) // Should be false after completion
    }
    
    // MARK: - User Model Tests
    
    func testUserModelEquality() {
        // Given
        let user1 = TestDataFactory.createTestUser(
            id: "123",
            email: "test@example.com",
            name: "Test User"
        )
        let user2 = TestDataFactory.createTestUser(
            id: "123",
            email: "test@example.com",
            name: "Test User"
        )
        let user3 = TestDataFactory.createTestUser(
            id: "456",
            email: "other@example.com",
            name: "Other User"
        )
        
        // Then
        XCTAssertEqual(user1, user2)
        XCTAssertNotEqual(user1, user3)
    }
    
    func testAuthSessionEquality() {
        // Given
        let user1 = TestDataFactory.createTestUser(id: "123")
        let user2 = TestDataFactory.createTestUser(id: "456")
        
        let session1 = TestDataFactory.createTestAuthSession(
            user: user1,
            accessToken: "token123"
        )
        let session2 = TestDataFactory.createTestAuthSession(
            user: user1,
            accessToken: "token123"
        )
        let session3 = TestDataFactory.createTestAuthSession(
            user: user2,
            accessToken: "token456"
        )
        
        // Then
        XCTAssertEqual(session1, session2)
        XCTAssertNotEqual(session1, session3)
    }
} 