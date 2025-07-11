# Golf Tracker iOS App

A beautiful SwiftUI golf tracking application with Supabase authentication, featuring a modern green-themed design.

## Features

- 🔐 **User Authentication** with Supabase
  - Email/password login and registration
  - OAuth support (Google & GitHub)
  - Secure session management
- ⛳ **Real-time Golf Tracking**
  - Personal dashboard with live statistics
  - Comprehensive round tracking
  - Automatic statistics calculation
  - Performance analytics and trends
- 🎨 **Modern UI Design**
  - Beautiful green-themed interface
  - Responsive SwiftUI components
  - Smooth animations and interactions

## Screenshots

The app includes beautifully designed login and registration screens with:
- Clean, modern interface with green gradient backgrounds
- White card-based forms with proper field validation
- OAuth integration buttons for Google and GitHub
- German language support

## Prerequisites

- Xcode 14.0 or later
- iOS 16.0 or later
- A Supabase account and project

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd GolfTracker
```

### 2. Add Supabase Dependency

1. Open the project in Xcode
2. Go to **File > Add Package Dependencies**
3. Add the Supabase Swift SDK:
   ```
   https://github.com/supabase/supabase-swift
   ```
4. Select the latest version

### 3. Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Create a new project
3. Note your **Project URL** and **Anon Key** from the project settings

### 4. Configure Supabase

1. Open `GolfTracker/SupabaseConfig.swift`
2. Replace the placeholder values:
   ```swift
   static let supabaseURL = "https://your-project-id.supabase.co"
   static let supabaseAnonKey = "your-anon-key-here"
   ```

### 5. Set Up Database Tables

1. In your Supabase dashboard, go to the **SQL Editor**
2. Copy and paste the contents of `supabase_schema.sql` (provided in the project root)
3. Run the SQL script to create all necessary tables:
   - `golf_rounds` - Stores individual golf rounds
   - `hole_scores` - Stores detailed hole-by-hole scores
   - `user_golf_stats` - Stores calculated user statistics
   - `golf_courses` - Optional course database
4. The script also sets up:
   - Row Level Security (RLS) policies for data protection
   - Automatic statistics calculation triggers
   - Sample golf courses data

### 6. Configure Authentication Providers (Optional)

For OAuth support, configure providers in your Supabase dashboard:

#### Google OAuth:
1. Create a project in [Google Cloud Console](https://console.cloud.google.com)
2. Enable Google+ API
3. Create OAuth 2.0 credentials
4. Add the credentials to Supabase Auth settings

#### GitHub OAuth:
1. Go to GitHub Developer Settings
2. Create a new OAuth App
3. Add the credentials to Supabase Auth settings

### 7. Build and Run

1. Select your target device or simulator
2. Build and run the project (⌘+R)

## Project Structure

```
GolfTracker/
├── Models/
│   └── User.swift                    # User data models
├── Services/
│   └── SupabaseAuthService.swift     # Authentication service
├── Views/
│   ├── LoginView.swift               # Login screen
│   ├── RegistrationView.swift        # Registration screen
│   └── DashboardView.swift           # Main dashboard
├── Coordinators/
│   └── AuthenticationCoordinator.swift # Navigation coordinator
└── SupabaseConfig.swift              # Configuration file
```

## Key Components

### Authentication Service
The `SupabaseAuthService` handles all authentication operations:
- User registration and login
- OAuth authentication
- Session management
- Error handling

### Views
- **LoginView**: Beautiful login interface matching the provided design
- **RegistrationView**: User registration with name, email, and password
- **DashboardView**: Main app interface with golf statistics
- **AuthenticationCoordinator**: Manages navigation between auth and main app

### Models
- **User**: Core user data structure
- **AuthSession**: Authentication session management

## Current Implementation

### ✅ Completed Features
- **User Authentication**: Complete login/registration system with Supabase
- **Real-time Dashboard**: Displays user's actual golf statistics from database
- **Data Models**: Comprehensive golf data structures
- **Database Integration**: Full Supabase integration with RLS policies
- **Responsive UI**: Optimized for iPhone with pull-to-refresh

### 🚧 Ready for Development
- **Round Entry**: Database structure ready, UI to be implemented
- **Detailed Analytics**: Advanced statistics and trends
- **Course Management**: Course database included
- **Social Features**: User data isolated and ready for sharing features

## 🗺️ Roadmap

### 🏆 Social & Gamification Features
- **🤝 Friend System**: Add friends to compete against and share statistics
- **📊 Leaderboards**: Compare performance with friends and global rankings
- **🎮 Achievements**: Unlock badges and rewards for golf milestones
- **📱 Social Sharing**: Share round results and achievements on social media

### 📲 User Experience & Engagement
- **🔔 Smart Notifications**: Remind users to play rounds and track progress
- **📱 Lock Screen Widget**: Show current hole number and progress bar during rounds
- **⌚ Apple Watch Integration**: Quick score entry and round tracking from wrist
- **📍 GPS Integration**: Automatic course detection and distance measurements

### 💎 Premium Features & Monetization
- **💳 Subscription Model**: Freemium approach with premium tier
- **🎯 Golf Pro AI Coach**: 
  - 📹 Video swing analysis using device camera
  - 🤖 AI-powered tips for improving technique and handicap
  - 📊 Advanced performance analytics and recommendations
  - 🎓 Personalized training programs
- **📈 Advanced Analytics**: 
  - Detailed shot tracking and club recommendations
  - Weather impact analysis on performance
  - Predictive handicap modeling
- **🏌️ Pro Features**:
  - Unlimited round storage
  - Export data to popular golf platforms
  - Priority customer support

### 🔮 Future Innovations
- **🥽 AR Features**: Augmented reality for course mapping and shot visualization
- **🤖 Voice Assistant**: "Hey Golf Pro" voice commands for hands-free score entry
- **📊 Tournament Mode**: Create and manage tournaments with friends
- **🌐 Course Reviews**: Community-driven course ratings and reviews

## Usage

### Authentication Flow
1. App launches and checks for existing session
2. If not authenticated, shows login screen
3. User can login with email/password or OAuth
4. Upon successful authentication, navigates to dashboard
5. Dashboard loads user's real golf statistics from Supabase
6. User can logout from dashboard

### Extending the App
The current implementation provides a solid foundation for a golf tracking app. You can extend it by:
- Adding golf round tracking
- Implementing score recording
- Creating statistics and analytics
- Adding course management
- Implementing social features

## Troubleshooting

### Common Issues

1. **Supabase connection errors**
   - Verify your URL and API key in `SupabaseConfig.swift`
   - Check your internet connection
   - Ensure your Supabase project is active

2. **OAuth not working**
   - Verify OAuth providers are configured in Supabase
   - Check redirect URLs are properly set
   - Ensure OAuth apps are properly configured

3. **Build errors**
   - Make sure Supabase Swift SDK is properly added
   - Clean build folder (⌘+Shift+K) and rebuild
   - Check iOS deployment target compatibility

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is available under the MIT License.

## Support

For questions or issues:
1. Check the troubleshooting section
2. Review Supabase documentation
3. Open an issue in this repository

---

**Note**: Remember to replace the placeholder Supabase credentials with your actual project credentials before running the app. 