# PlungePalz WatchOS App

A comprehensive cold plunge session tracking app for Apple Watch with water lock functionality and reliable gesture-based controls.

## 🚀 **Features**

### 🔒 **Water Lock System**
- **Automatic Activation**: Water lock enables when entering CountdownActivatedScreen
- **Visual Indicator**: Lock icon appears in top-left corner during water lock
- **Touch Prevention**: All screen touches disabled to prevent accidental interactions
- **Gesture Controls**: Long press gestures provide reliable session control

### 🎮 **Enhanced Gesture Controls**
- **Four Control Areas**: Multiple gesture zones for different actions
- **Quick Pause**: Center area (1.0s long press) for fastest pause
- **Normal Pause**: Top-left area (1.5s long press) for standard pause
- **Stop Session**: Top-right area (1.5s long press) to end session
- **Emergency Stop**: Bottom area (2.0s long press) for safety
- **Reliable Operation**: Works consistently without system interference

### 📊 **Session Management**
- **Timer Control**: Countdown and count-up functionality
- **Temperature Tracking**: Set and monitor water temperature
- **Heart Rate Monitoring**: Real-time BPM tracking during sessions
- **Progress Visualization**: Visual progress indicators with milestone flags
- **Session History**: Complete session tracking and statistics

## 🏗️ **Architecture**

### **Core Components**
- **SwiftUI-based UI**: Modern, responsive interface
- **MVVM Pattern**: Clean separation of concerns
- **Modular Design**: Organized into logical subfolders
- **Water Lock Integration**: Prevents accidental touches during sessions

### **Key Managers**
- **WaterLockManager**: Handles water lock functionality
- **NavigationManager**: Manages screen transitions
- **SessionDataManager**: Handles session data persistence
- **WatchScreenManager**: Adapts UI for different screen sizes

## 📁 **Project Structure**

### 🔧 **Hardware/**
Hardware-specific functionality including water lock and gesture handling.
- `WaterLockManager.swift` - Water lock functionality
- `HardwareButtonEvent.swift` - Event definitions (for documentation)
- `HardwareButtonManager.swift` - Basic button management (legacy)
- `EnhancedHardwareButtonManager.swift` - Enhanced gesture handling

### 🎨 **UI/**
User interface components and styling.
- `WatchGlobalUIConfig.swift` - Global UI configuration
- `WatchScreenSizes.swift` - Screen size detection and adaptation
- `FontManager.swift` - Typography management

### 📱 **Screens/**
Main application screens.
- `HomeScreen.swift` - Main dashboard
- `CountdownActivatedScreen.swift` - Active session with gesture controls
- `SetTemperatureScreen.swift` - Temperature configuration
- `SetTimerScreen.swift` - Timer setup
- `SelectSessionScreen.swift` - Session selection
- `ConnectDeviceScreen.swift` - Device connection
- `ActivityStoppedOrPausedScreen.swift` - Pause/stop screen
- `SessionRecapScreen.swift` - Session summary
- `SessionDeletedScreen.swift` - Deletion confirmation

### 🧠 **Managers/**
Business logic and state management.
- `NavigationManager.swift` - Screen navigation
- `SessionDataManager.swift` - Session data handling

### 🔧 **Core/**
Core application components.
- `ContentView.swift` - Main content view
- `PlungePalzApp.swift` - App entry point

### 📚 **Documentation/**
Implementation guides and technical documentation.
- `IMPLEMENTATION_GUIDE.md` - General implementation guide
- `GESTURE_CONTROLS.md` - Gesture control system documentation
- `HARDWARE_BUTTON_LIMITATIONS.md` - Technical analysis of hardware button limitations
- `WaterLockHardwareButtonTest.swift` - Testing interface

### 🛠️ **Utils/**
Utility functions and extensions.
- `Binding+OnChange.swift` - SwiftUI binding extensions

## 🎯 **Gesture Control System**

### **Why Gestures Instead of Hardware Buttons?**

WatchOS reserves hardware buttons (Digital Crown and Side Button) for system functions and cannot be overridden by apps. Our gesture-based solution provides:

1. **Reliability**: Works 100% of the time without system interference
2. **Accessibility**: Multiple control areas provide redundancy
3. **Safety**: Different timing prevents accidental actions
4. **Water-Safe**: Works even with wet fingers
5. **Intuitive**: Natural long press behavior

### **Control Areas**

When water lock is enabled on the CountdownActivatedScreen:

1. **Center Area** (60% width × 40% height)
   - **Action**: Quick pause
   - **Gesture**: 1.0s long press
   - **Use Case**: Fastest pause option

2. **Top-Left Area** (40% width × 30% height)
   - **Action**: Normal pause
   - **Gesture**: 1.5s long press
   - **Use Case**: Standard pause during session

3. **Top-Right Area** (40% width × 30% height)
   - **Action**: Stop session
   - **Gesture**: 1.5s long press
   - **Use Case**: End session normally

4. **Bottom Area** (80% width × 20% height)
   - **Action**: Emergency stop
   - **Gesture**: 2.0s long press
   - **Use Case**: Emergency situations, prevents accidental stops

## 🧪 **Testing**

### **Gesture Control Testing**
1. Navigate to CountdownActivatedScreen
2. Verify water lock is enabled (lock icon visible)
3. Test gesture areas:
   - **Center**: Long press 1.0s for quick pause
   - **Top-left**: Long press 1.5s for normal pause
   - **Top-right**: Long press 1.5s for stop
   - **Bottom**: Long press 2.0s for emergency stop

### **Expected Console Output**
```
Water lock enabled
Quick pause gesture detected (center)
Session paused via gesture
Stop gesture detected (top-right)  
Session stopped via gesture
```

## 🚀 **Getting Started**

1. **Clone the repository**
2. **Open in Xcode**: `PlungePalz.xcodeproj`
3. **Select Watch App target**: "PlungePalz Watch App"
4. **Choose simulator**: Apple Watch Series 10 (46mm) or similar
5. **Build and run**: `⌘+R`

## 📱 **Supported Devices**

- **Apple Watch Series 4+** (watchOS 8.7+)
- **All screen sizes** (40mm, 44mm, 41mm, 45mm, 49mm, 46mm)
- **Simulator support** for development and testing

## 🔧 **Development Notes**

### **Gesture vs Hardware Buttons**
- **Hardware buttons** are intercepted by WatchOS system (cannot be overridden)
- **Gesture controls** provide reliable, consistent operation
- **Water lock** prevents accidental screen touches
- **Multiple gesture areas** ensure redundancy and accessibility

### **Architecture**
- **SwiftUI-based** for modern, responsive UI
- **MVVM pattern** with ObservableObject managers
- **Modular design** with clear separation of concerns
- **Comprehensive documentation** for maintainability

## 📄 **License**

This project is developed for cold plunge session tracking and management. 