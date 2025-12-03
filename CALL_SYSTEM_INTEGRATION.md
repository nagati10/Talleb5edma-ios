# Call System Integration Guide

## Step 1: Add Permissions to Info.plist

Add these permissions to your `Info.plist` file (or use the GUI editor in Xcode):

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access for video calls with companies.</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice and video calls.</string>
```

**Note:** You already have `NSMicrophoneUsageDescription` and `NSPhotoLibraryUsageDescription` from the chat features. If `NSCameraUsageDescription` is missing, add it.

---

## Step 2: Update Your App Root

You need to add the CallManager and incoming call overlay to your app's root view. Here's how based on different app structures:

### Option A: If you have a main TabView or ContentView

Add this at the root level (usually in your `@main App` struct or main `ContentView`):

```swift
import SwiftUI

@main
struct Taleb_5edmaApp: App {
    @StateObject private var callManager = CallManager.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Your existing app content
                MainTabView() // or whatever your root view is
                
                // Global incoming call overlay
                if case .incomingCall(let callData) = callManager.callState {
                    IncomingCallOverlay(
                        callData: callData,
                        onAccept: {
                            callManager.acceptCall()
                            // Navigate to CallView - see navigation options below
                        },
                        onReject: {
                            callManager.rejectCall()
                        }
                    )
                    .transition(.opacity)
                    .zIndex(999)
                }
            }
            .onAppear {
                // Connect to call server when app launches
                if let userId = UserDefaults.standard.string(forKey: "userId"),
                   !userId.isEmpty {
                    let userName = UserDefaults.standard.string(forKey: "userName") ?? "User"
                    callManager.connect(userId: userId, userName: userName)
                }
            }
        }
    }
}
```

### Option B: If you use NavigationStack/NavigationView

Wrap your navigation content:

```swift
struct MainTabView: View {
    @StateObject private var callManager = CallManager.shared
    @State private var showCallView = false
    @State private var callViewData: (userId: String, userName: String, isVideo: Bool, chatId: String?)?
    
    var body: some View {
        ZStack {
            NavigationStack {
                // Your existing content
                TabView {
                    // ... tabs
                }
                .navigationDestination(isPresented: $showCallView) {
                    if let data = callViewData {
                        CallView(
                            toUserId: data.userId,
                            toUserName: data.userName,
                            isVideoCall: data.isVideo,
                            chatId: data.chatId
                        )
                    }
                }
            }
            
            // Incoming call overlay
            if case .incomingCall(let callData) = callManager.callState {
                IncomingCallOverlay(
                    callData: callData,
                    onAccept: {
                        callManager.acceptCall()
                        callViewData = (
                            callData.fromUserId,
                            callData.fromUserName,
                            callData.isVideoCall,
                            callData.chatId
                        )
                        showCallView = true
                    },
                    onReject: {
                        callManager.rejectCall()
                    }
                )
                .zIndex(999)
            }
        }
        .onAppear {
            if let userId = UserDefaults.standard.string(forKey: "userId"),
               !userId.isEmpty {
                let userName = UserDefaults.standard.string(forKey: "userName") ?? "User"
                callManager.connect(userId: userId, userName: userName)
            }
        }
    }
}
```

---

## Step 3: Update ChatView Navigation

Update your ChatView to navigate to the new CallView with proper parameters:

```swift
// In ChatView.swift
.sheet(isPresented: $viewModel.showingCall) {
    if let chatId = viewModel.currentChatId {
        CallView(
            toUserId: "COMPANY_USER_ID", // Get from chat details
            toUserName: "Company Name",  // Get from chat details
            isVideoCall: viewModel.isVideoCall,
            chatId: chatId
        )
    }
}
```

**TODO:** You'll need to store the company/other user's information when loading the chat, so you can pass it to CallView.

---

## Step 4: Get Other User Info in ChatViewModel

Update `ChatViewModel` to store the other user's information:

```swift
// Add to ChatViewModel properties
@Published var otherUserId: String?
@Published var otherUserName: String?

// When loading chat, extract the other user info
// This depends on your chat data structure
// Example:
func loadChatHistory() {
    Task {
        do {
            if let chatId = currentChatId {
                let messagesResponse = try await chatService.getChatMessages(chatId: chatId)
                
                // Get chat details to find other user
                // Assuming you have chat details in the response or need separate call
                // Extract otherUserId and otherUserName from chat participants
                
                await MainActor.run {
                    self.messages = self.convertToChatMessages(messagesResponse.messages)
                    self.isLoading = false
                }
            }
        } catch {
            // ...
        }
    }
}
```

Then update `initiateCall`:

```swift
func initiateCall(isVideoCall: Bool) {
    guard let chatId = currentChatId else {
        errorMessage = "No active chat"
        return
    }
    
    guard let userId = currentUserId else {
        errorMessage = "User not logged in"
        return
    }
    
    guard let toUserId = otherUserId,
          let toUserName = otherUserName else {
        errorMessage = "Cannot find user to call"
        return
    }
    
    self.isVideoCall = isVideoCall
    self.showingCall = true
    
    let callManager = CallManager.shared
    
    if !callManager.isConnected {
        let userName = UserDefaults.standard.string(forKey: "userName") ?? "User"
        callManager.connect(userId: userId, userName: userName)
    }
    
    callManager.makeCall(
        toUserId: toUserId,
        toUserName: toUserName,
        isVideoCall: isVideoCall,
        chatId: chatId
    )
}
```

---

## Step 5: Test the Integration

### Test Outgoing Call:
1. Run the app
2. Go to a chat
3. Click the phone or video icon
4. Should see CallView with "Calling..." status
5. Check Xcode console for WebSocket logs

### Test Incoming Call (requires two devices/simulators):
1. Run app on two devices with different user IDs
2. From device A, initiate call to device B
3. Device B should show incoming call overlay
4. Accept/decline should work

### Expected Console Logs:
```
🔌 Connecting to WebSocket server...
✅ Connected to WebSocket server
📝 Registering user: USER_ID
✅ User registered successfully
📞 Making call to Company: {...}
📞 Call request sent successfully
```

---

## Troubleshooting

### "Not connected to server"
- Check that baseURL in APIConfig is correct
- Verify WebSocket server is running
- Check network connectivity

### "No incoming call popup"
- Verify CallManager is initialized at app root
- Check that IncomingCallOverlay is in ZStack with high zIndex
- Confirm both users are registered with server

### Permissions denied
- Go to Settings → Taleb_5edma → Allow camera/microphone

---

## Next Steps (Future Implementation)

1. **WebRTC Integration** - Add actual video/audio streaming
2. **Media Stream Manager** - Implement camera/microphone capture
3. **Push Notifications** - VoIP push for background calls
4. **CallKit Integration** - iOS native call interface

---

## Current Limitations

- ✅ WebSocket signaling works
- ✅ Call state management works
- ✅ UI shows call status
- ❌ No actual video/audio streaming yet (needs WebRTC)
- ❌ No camera preview (needs MediaStreamManager)
- ❌ No background call support (needs VoIP push)

The foundation is complete! WebRTC implementation is the next major phase.
