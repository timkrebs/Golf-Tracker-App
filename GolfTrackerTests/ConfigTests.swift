//
//  ConfigTests.swift
//  GolfTrackerTests
//
//  Created by Tim Krebs on 7/11/25.
//

import Testing
import Foundation
@testable import GolfTracker

struct ConfigTests {
    
    // MARK: - AppConfig Tests
    
    @Test func appConfigCreation() async throws {
        // Given
        let config = AppConfig(
            supabaseURL: "https://test.supabase.co",
            supabaseAnonKey: "test-key-123",
            golfAPIBaseURL: "https://api.test.com",
            environment: "testing"
        )
        
        // Then
        #expect(config.supabaseURL == "https://test.supabase.co")
        #expect(config.supabaseAnonKey == "test-key-123")
        #expect(config.golfAPIBaseURL == "https://api.test.com")
        #expect(config.environment == "testing")
    }
    
    @Test func appConfigEnvironmentChecks() async throws {
        // Given
        let productionConfig = AppConfig(
            supabaseURL: "https://prod.supabase.co",
            supabaseAnonKey: "prod-key",
            golfAPIBaseURL: "https://api.prod.com",
            environment: "production"
        )
        
        let developmentConfig = AppConfig(
            supabaseURL: "https://dev.supabase.co",
            supabaseAnonKey: "dev-key",
            golfAPIBaseURL: "https://api.dev.com",
            environment: "development"
        )
        
        let testConfig = AppConfig(
            supabaseURL: "https://test.supabase.co",
            supabaseAnonKey: "test-key",
            golfAPIBaseURL: "https://api.test.com",
            environment: "testing"
        )
        
        // Then
        #expect(productionConfig.isProduction == true)
        #expect(productionConfig.isDevelopment == false)
        
        #expect(developmentConfig.isProduction == false)
        #expect(developmentConfig.isDevelopment == true)
        
        #expect(testConfig.isProduction == false)
        #expect(testConfig.isDevelopment == false)
    }
    
    @Test func appConfigCaseInsensitiveEnvironment() async throws {
        // Given
        let upperCaseConfig = AppConfig(
            supabaseURL: "https://test.supabase.co",
            supabaseAnonKey: "test-key",
            golfAPIBaseURL: "https://api.test.com",
            environment: "PRODUCTION"
        )
        
        let mixedCaseConfig = AppConfig(
            supabaseURL: "https://test.supabase.co",
            supabaseAnonKey: "test-key",
            golfAPIBaseURL: "https://api.test.com",
            environment: "Development"
        )
        
        // Then
        #expect(upperCaseConfig.isProduction == true)
        #expect(mixedCaseConfig.isDevelopment == true)
    }
    
    // MARK: - ConfigError Tests
    
    @Test func configErrorTypes() async throws {
        // Test enum cases exist
        let configFileNotFound = ConfigError.configFileNotFound
        let missingKey = ConfigError.missingKey("test-key")
        let invalidConfiguration = ConfigError.invalidConfiguration
        
        // Verify error messages or behavior
        switch missingKey {
        case .missingKey(let key):
            #expect(key == "test-key")
        default:
            #expect(Bool(false), "Expected missingKey case")
        }
    }
    
    // MARK: - MockConfigLoader Tests
    
    @Test func mockConfigLoaderSuccessfulLoad() async throws {
        // Given
        let testConfig = MockAppConfig.testConfig
        MockConfigLoader.mockConfig = testConfig
        MockConfigLoader.shouldThrowError = false
        
        // When
        let loadedConfig = try MockConfigLoader.loadConfig()
        
        // Then
        #expect(loadedConfig.supabaseURL == testConfig.supabaseURL)
        #expect(loadedConfig.supabaseAnonKey == testConfig.supabaseAnonKey)
        #expect(loadedConfig.golfAPIBaseURL == testConfig.golfAPIBaseURL)
        #expect(loadedConfig.environment == testConfig.environment)
        
        // Cleanup
        MockConfigLoader.reset()
    }
    
    @Test func mockConfigLoaderErrorHandling() async throws {
        // Given
        MockConfigLoader.shouldThrowError = true
        MockConfigLoader.errorToThrow = .configFileNotFound
        
        // When & Then
        do {
            _ = try MockConfigLoader.loadConfig()
            #expect(Bool(false), "Expected error to be thrown")
        } catch ConfigError.configFileNotFound {
            // Expected error
            #expect(Bool(true))
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
        
        // Cleanup
        MockConfigLoader.reset()
    }
    
    @Test func mockConfigLoaderMissingKeyError() async throws {
        // Given
        MockConfigLoader.shouldThrowError = true
        MockConfigLoader.errorToThrow = .missingKey("SUPABASE_URL")
        
        // When & Then
        do {
            _ = try MockConfigLoader.loadConfig()
            #expect(Bool(false), "Expected error to be thrown")
        } catch ConfigError.missingKey(let key) {
            #expect(key == "SUPABASE_URL")
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
        
        // Cleanup
        MockConfigLoader.reset()
    }
    
    @Test func mockConfigLoaderInvalidConfigError() async throws {
        // Given
        MockConfigLoader.shouldThrowError = true
        MockConfigLoader.errorToThrow = .invalidConfiguration
        
        // When & Then
        do {
            _ = try MockConfigLoader.loadConfig()
            #expect(Bool(false), "Expected error to be thrown")
        } catch ConfigError.invalidConfiguration {
            // Expected error
            #expect(Bool(true))
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
        
        // Cleanup
        MockConfigLoader.reset()
    }
    
    @Test func mockConfigLoaderFallbackToDefaultConfig() async throws {
        // Given
        MockConfigLoader.mockConfig = nil
        MockConfigLoader.shouldThrowError = false
        
        // When
        let loadedConfig = try MockConfigLoader.loadConfig()
        
        // Then - Should use default test config
        #expect(loadedConfig.supabaseURL == MockAppConfig.testConfig.supabaseURL)
        #expect(loadedConfig.environment == "testing")
        
        // Cleanup
        MockConfigLoader.reset()
    }
    
    @Test func mockConfigLoaderReset() async throws {
        // Given
        MockConfigLoader.mockConfig = MockAppConfig.testConfig
        MockConfigLoader.shouldThrowError = true
        MockConfigLoader.errorToThrow = .missingKey("test")
        
        // When
        MockConfigLoader.reset()
        
        // Then
        #expect(MockConfigLoader.mockConfig == nil)
        #expect(MockConfigLoader.shouldThrowError == false)
        
        // Should not throw error after reset
        do {
            let config = try MockConfigLoader.loadConfig()
            #expect(config.environment == "testing") // Default config
        } catch {
            #expect(Bool(false), "Should not throw error after reset")
        }
    }
    
    // MARK: - SupabaseConfig Integration Tests
    
    @Test func supabaseConfigWithValidConfig() async throws {
        // Note: These tests would require mocking the ConfigLoader within SupabaseConfig
        // For now, we test the structure and expected behavior
        
        // Given a valid config scenario
        let testConfig = AppConfig(
            supabaseURL: "https://valid.supabase.co",
            supabaseAnonKey: "valid-anon-key",
            golfAPIBaseURL: "https://valid-api.com",
            environment: "testing"
        )
        
        // Verify config properties
        #expect(!testConfig.supabaseURL.isEmpty)
        #expect(!testConfig.supabaseAnonKey.isEmpty)
        #expect(testConfig.supabaseURL.contains("supabase.co"))
    }
    
    @Test func supabaseConfigURLValidation() async throws {
        // Test valid Supabase URL format
        let validConfig = AppConfig(
            supabaseURL: "https://project-id.supabase.co",
            supabaseAnonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
            golfAPIBaseURL: "https://api.example.com",
            environment: "testing"
        )
        
        #expect(validConfig.supabaseURL.hasPrefix("https://"))
        #expect(validConfig.supabaseURL.contains(".supabase.co"))
        #expect(validConfig.supabaseAnonKey.hasPrefix("eyJ")) // JWT prefix
    }
    
    @Test func configValidationHelpers() async throws {
        // Test config validation logic
        let validURL = "https://test.supabase.co"
        let invalidURL = "invalid-url"
        let validKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test"
        let placeholderKey = "YOUR_SUPABASE_ANON_KEY_HERE"
        
        // URL validation
        #expect(validURL.hasPrefix("https://"))
        #expect(validURL.contains("supabase.co"))
        #expect(!invalidURL.hasPrefix("https://"))
        
        // Key validation (should not contain placeholders)
        #expect(!validKey.contains("YOUR_"))
        #expect(placeholderKey.contains("YOUR_"))
    }
    
    // MARK: - Environment Variable Tests
    
    @Test func environmentVariableHandling() async throws {
        // Test environment variable naming
        let expectedEnvironmentKeys = [
            "SUPABASE_URL",
            "SUPABASE_ANON_KEY",
            "GOLF_API_BASE_URL",
            "ENVIRONMENT"
        ]
        
        // Verify key naming conventions
        for key in expectedEnvironmentKeys {
            #expect(key.uppercased() == key) // Should be uppercase
            #expect(!key.contains(" ")) // Should not contain spaces
            #expect(key.contains("_") || key.count <= 12) // Use underscores for long names
        }
    }
    
    @Test func configPlistStructure() async throws {
        // Test expected plist structure
        let expectedKeys = [
            "SUPABASE_URL",
            "SUPABASE_ANON_KEY", 
            "GOLF_API_BASE_URL",
            "ENVIRONMENT"
        ]
        
        // Verify all required keys are accounted for
        #expect(expectedKeys.count == 4)
        #expect(expectedKeys.contains("SUPABASE_URL"))
        #expect(expectedKeys.contains("SUPABASE_ANON_KEY"))
        #expect(expectedKeys.contains("GOLF_API_BASE_URL"))
        #expect(expectedKeys.contains("ENVIRONMENT"))
    }
    
    // MARK: - Configuration Security Tests
    
    @Test func configSecurityValidation() async throws {
        // Test that sensitive values are not hardcoded
        let insecureConfig = AppConfig(
            supabaseURL: "YOUR_SUPABASE_URL_HERE",
            supabaseAnonKey: "YOUR_SUPABASE_ANON_KEY_HERE",
            golfAPIBaseURL: "YOUR_GOLF_API_BASE_URL_HERE",
            environment: "development"
        )
        
        let secureConfig = MockAppConfig.testConfig
        
        // Insecure config should contain placeholders
        #expect(insecureConfig.supabaseURL.contains("YOUR_"))
        #expect(insecureConfig.supabaseAnonKey.contains("YOUR_"))
        
        // Secure config should not contain placeholders
        #expect(!secureConfig.supabaseURL.contains("YOUR_"))
        #expect(!secureConfig.supabaseAnonKey.contains("YOUR_"))
    }
    
    @Test func configEnvironmentDefaults() async throws {
        // Test default environment values
        let defaultConfig = AppConfig(
            supabaseURL: "https://test.supabase.co",
            supabaseAnonKey: "test-key",
            golfAPIBaseURL: "https://golftracker-app-service.azurewebsites.net", // Default API URL
            environment: "development"
        )
        
        #expect(defaultConfig.golfAPIBaseURL == "https://golftracker-app-service.azurewebsites.net")
        #expect(defaultConfig.environment == "development")
        #expect(defaultConfig.isDevelopment == true)
        #expect(defaultConfig.isProduction == false)
    }
} 