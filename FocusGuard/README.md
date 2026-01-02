# FocusGuard - Eye Tracking Focus App for macOS

A macOS application that uses eye tracking to monitor focus and block distracting applications until a configurable focus goal is achieved.

## Features

### Eye Tracking
- Uses the built-in camera and Apple's Vision framework for face/eye detection
- Tracks whether you're looking at the screen
- Pauses focus time accumulation when you look away
- Configurable distraction threshold (how long before looking away counts)

### App Blocking
- Blocks distracting applications during focus sessions
- Two modes:
  - **Block List**: Block specific apps (default)
  - **Allow List**: Only allow specific apps during focus
- Automatically terminates blocked apps when they launch
- Pre-configured list of common distracting apps (social media, games, etc.)
- Add custom apps by bundle identifier

### Focus Sessions
- Configurable focus goal (default: 8 hours)
- Real-time progress tracking with visual progress ring
- Session statistics (time accumulated, distractions, current streak)
- Optional breaks at configurable intervals

### Rewards System
- Set a virtual reward amount for completing focus goals
- Track total rewards earned over time
- Achievement badges for milestones

### Bypass Protection
- Cannot quit the app or end session until goal is reached
- Emergency bypass requires contacting a configurable email address
- Bypass code system for verified requests

## Requirements

- macOS 13.0 (Ventura) or later
- Mac with built-in or external camera
- Accessibility permission (for app blocking)
- Camera permission (for eye tracking)

## Installation

1. Open `FocusGuard.xcodeproj` in Xcode 15+
2. Select your development team for code signing
3. Build and run (⌘R)

## Permissions

The app requires the following permissions:

### Camera Access
Required for eye tracking. The app uses the Vision framework to detect face and eye landmarks to determine if you're looking at the screen.

### Accessibility Access
Required to terminate blocked applications. Go to System Settings > Privacy & Security > Accessibility and enable FocusGuard.

## Usage

### Starting a Focus Session

1. Launch FocusGuard
2. Configure your blocked/allowed apps in the "Blocked Apps" section
3. Set your focus goal and reward in Settings
4. Click "Start Focus Session" from the Dashboard

### During a Session

- The app tracks when your face is detected and eyes are looking at the screen
- Focus time only accumulates when you're actively looking at the screen
- Looking away for more than the distraction threshold pauses time accumulation
- Blocked apps are automatically terminated if launched

### Ending a Session

Sessions end automatically when the focus goal is reached. If you need to end early:
1. Go to the Session view
2. Click "Request Emergency Bypass"
3. Contact the configured email address for a bypass code
4. Enter the code to end the session

## Configuration

### Focus Settings
- **Focus Hours Required**: Hours of focus time needed to complete a session (0.5 - 12 hours)
- **Distraction Threshold**: Seconds of looking away before time stops accumulating (1-10 seconds)

### Reward Settings
- **Currency Symbol**: The symbol for your virtual currency
- **Reward Amount**: Amount earned per completed session

### Break Settings
- **Enable Breaks**: Allow taking scheduled breaks
- **Break Duration**: Length of each break (1-30 minutes)
- **Break Interval**: Time between available breaks (15-120 minutes)

### Bypass Settings
- **Bypass Contact Email**: Email address users must contact to request emergency bypass

## Architecture

```
FocusGuard/
├── FocusGuardApp.swift          # App entry point and delegate
├── Managers/
│   ├── EyeTrackingManager.swift    # Camera and Vision framework integration
│   ├── AppBlockerManager.swift     # App termination and monitoring
│   ├── SettingsManager.swift       # UserDefaults persistence
│   └── FocusSessionManager.swift   # Session state coordination
├── Views/
│   ├── ContentView.swift           # Main navigation
│   ├── DashboardView.swift         # Home screen with quick start
│   ├── SessionView.swift           # Active session display
│   ├── AppManagementView.swift     # App blocking configuration
│   ├── SettingsView.swift          # User preferences
│   └── StatisticsView.swift        # Progress and achievements
├── Info.plist                      # App configuration and permissions
└── FocusGuard.entitlements         # App capabilities
```

## How Eye Tracking Works

1. The camera captures video frames
2. Vision framework detects faces in each frame
3. For each detected face, we analyze:
   - Eye landmark positions (left and right eyes)
   - Pupil positions relative to eye centers
   - Eye aspect ratio (to detect if eyes are open)
   - Face position in frame (to detect if looking at screen)
4. If eyes are open and pupils are centered (not looking far left/right), we consider the user focused
5. Focus time accumulates during focused periods

## Privacy

- All eye tracking is done locally on-device
- No video or images are stored or transmitted
- Camera is only active during focus sessions
- Settings are stored locally in UserDefaults

## License

MIT License - See LICENSE file for details
