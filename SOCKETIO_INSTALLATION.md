# Adding Socket.IO Dependency to Your Project

## Method 1: Swift Package Manager (Recommended)

1. **Open your Xcode project**

2. **Go to File → Add Packages...**

3. **Enter the Socket.IO repository URL:**
   ```
   https://github.com/socketio/socket.io-client-swift
   ```

4. **Select version:**
   - Dependency Rule: `Up to Next Major Version`
   - Version: `16.0.0`

5. **Click "Add Package"**

6. **Select the target** (`Taleb_5edma`) and click "Add Package"

7. **Verify installation:**
   - The package should appear in your Project Navigator under "Package Dependencies"

## Method 2: CocoaPods (Alternative)

If you prefer CocoaPods:

1. **Create or edit `Podfile` in your project root:**
   ```ruby
   platform :ios, '15.0'

   target 'Taleb_5edma' do
     use_frameworks!
     
     # Socket.IO for WebSocket communication
     pod 'Socket.IO-Client-Swift', '~> 16.0.0'
   end
   ```

2. **Install:**
   ```bash
   pod install
   ```

3. **Open the `.xcworkspace` file** (not `.xcodeproj`)

## Verification

After installation, verify by building the project:
1. Press `Cmd + B` to build
2. Check for any import errors in `WebSocketManager.swift`
3. The line `import SocketIO` should not show any errors

## Troubleshooting

### "No such module 'SocketIO'" error:
1. Clean build folder: `Cmd + Shift + K`
2. Delete derived data: `Cmd + Shift + Option + K`
3. Rebuild project: `Cmd + B`

### SPM cache issues:
1. File → Packages → Reset Package Caches
2. File → Packages → Update to Latest Package Versions

## Next Steps

After Socket.IO is installed:
1. Build the project to ensure no errors
2. We'll continue with WebRTCManager implementation
3. Then MediaStreamManager for camera/microphone access

---

**Note:** The Socket.IO package is MIT licensed and actively maintained. It's the same library used in many production iOS apps for WebSocket communication.
