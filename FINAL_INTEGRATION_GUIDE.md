# 🎯 COMPLETE Call System Integration - Step by Step

## ✅ What's Already Done

1. ✅ Socket.IO dependency installed
2. ✅ All call system files created
3. ✅ ChatView updated to use new CallView
4. ✅ CallViewModel and CallManager ready
5. ✅ IncomingCallOverlay created
6. ✅ CallCoordinator for global state
7. ✅ AppRootView wrapper created

---

## 🚀 Final Integration Steps (5 minutes)

### Step 1: Update Your App Entry Point

Find your `@main` struct (usually in a file like `Taleb_5edmaApp.swift` or similar).

**Replace this:**
```swift
@main
struct Taleb_5edmaApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView() // or ContentView, or whatever your root is
        }
    }
}
```

**With this:**
```swift
@main
struct Taleb_5edmaApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView {
                MainTabView() // Your existing root view - keep it!
            }
        }
    }
}
```

That's it! The `AppRootView` wraps your existing app and adds:
- Global incoming call overlay
- Automatic CallView navigation
- WebSocket connection management

---

### Step 2: Add Camera Permission (if not already added)

Open `Info.plist` and verify you have:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access for video calls with companies.</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice and video calls.</string>
```

**Note:** You already have microphone permission from audio messages. Just add camera if missing.

---

### Step 3: Get Company User ID (Important!)

Currently, `ChatView` passes `"company_user_id"` as a placeholder. You need to get the actual other user's ID from your chat.

**Option A:** If you have it in the `Offre` object:
```swift
// In ChatView.swift, update the CallView presentation:
.fullScreenCover(isPresented: $viewModel.showingCall) {
    CallView(
        toUserId: offre?.userId ?? "unknown", // Get from your offre
        toUserName: getChatTitle(),
        isVideoCall: viewModel.isVideoCall,
        chatId: viewModel.currentChatId
    )
}
```

**Option B:** Add other user info to ChatViewModel:
```swift
// In ChatViewModel.swift, add properties:
@Published var otherUserId: String?
@Published var otherUserName: String?

// When loading chat messages, extract the other user:
// (Depends on your chat structure - you might need to make an API call)
```

Then in ChatView:
```swift
.fullScreenCover(isPresented: $viewModel.showingCall) {
    CallView(
        toUserId: viewModel.otherUserId ?? "unknown",
        toUserName: viewModel.otherUserName ?? getChatTitle(),
        isVideoCall: viewModel.isVideoCall,
        chatId: viewModel.currentChatId
    )
}
```

---

## 📱 How It Works Now

### Making a Call (Outgoing):
1. User clicks phone/video icon in ChatView
2. `ChatViewModel.initiateCall()` is called
3. `CallManager.shared.makeCall()` sends WebSocket signal
4. **CallCoordinator automatically shows CallView**
5. User sees "Calling..." screen with their controls
6. WebSocket sends `call-request` to server
7. Server forwards to recipient

### Receiving a Call (Incoming):
1. WebSocket receives `incoming-call` event
2. **CallCoordinator shows IncomingCallOverlay globally**
3. Overlay appears on top of ANY screen (chat, profile, home, etc.)
4. User taps Accept → CallView opens automatically
5. User taps Decline → overlay dismisses

### During Call:
- Toggle video/audio (UI only for now, WebRTC needed for actual stream)
- Switch camera (placeholder)
- End call → dismisses and notifies other user

### Call States:
- ✅ Idle
- ✅ Connecting
- ✅ Outgoing Call (Calling...)
- ✅ Incoming Call (Popup)
- ✅ In Call (Connected)
- ✅ Call Failed (Shows reason)
- ✅ Ended (Auto-dismiss after 1s)

---

## 🧪 Testing Checklist

### Test 1: WebSocket Connection
1. Run app
2. Check Xcode console for:
   ```
   🔌 Connecting to WebSocket server...
   ✅ Connected to WebSocket server
   📝 Registering user: USER_ID
   ✅ User registered successfully
   ```

### Test 2: Outgoing Call
1. Go to any chat
2. Click phone or video icon
3. Should see CallView with "Calling..." status
4. Console should show:
   ```
   📞 Making call to Company: {...}
   📞 Call request sent successfully
   ```
5. After 30s, should timeout if not answered

### Test 3: Call Controls
1. While in CallView, test:
   - Video toggle (icon changes)
   - Audio toggle (icon changes)
   - Hang up (dismisses view)
2. Console logs show each action

### Test 4: Incoming Call (requires 2 devices)
1. Run app on Device A and Device B
2. Different user IDs on each
3. From Device A, call Device B
4. Device B should see incoming call popup **anywhere in app**
5. Accept → opens CallView
6. Decline → dismisses popup

---

## 🐛 Troubleshooting

### Issue: "Cannot find AppRootView in scope"
**Fix:** Make sure you created `AppRootView.swift` file

### Issue: "Cannot find CallCoordinator"
**Fix:** Make sure you created `CallCoordinator.swift` file

### Issue: WebSocket not connecting
**Fix:** 
- Check `APIConfig.baseURL` is correct
- Verify backend server is running
- Check network connectivity

### Issue: Incoming call popup doesn't appear
**Fix:**
- Verify `AppRootView` wraps your app root
- Check both users are registered (check console logs)
- Ensure WebSocket connection is active

### Issue: "company_user_id" in calls
**Fix:** Follow Step 3 above to get real user ID from chat/offer

---

## 📊 Current System Status

### ✅ Working:
- WebSocket signaling (make, accept, reject, end calls)
- Call state management
- UI updates based on call state
- Timeout handling (30s)
- Global incoming call notifications
- Navigation to CallView from anywhere
- Auto-dismiss on call end

### ⏳ Not Yet Implemented:
- Actual video/audio streaming (needs WebRTC)
- Camera preview (placeholder only)
- Real microphone/speaker (needs MediaStreamManager)
- Background calls (needs VoIP push)
- Call Kit integration

---

## 🎬 Next Steps

### Immediate:
1. ✅ Wrap app with `AppRootView` (5 min)
2. ✅ Add camera permission (1 min)
3. ✅ Fix company user ID (5-10 min)
4. 🧪 Test with console logs (10 min)

### Future (WebRTC Phase):
WebRTC requires ~10-12 hours to implement:
- Add WebRTC iOS SDK
- Create WebRTCManager
- Implement peer connection
- Add actual camera/mic streaming
- Test on real devices

---

## 💡 Pro Tips

1. **Check console logs** - they tell you exactly what's happening
2. **Test on real device** - simulator can't test camera/mic
3. **Use 2 devices** for full call testing
4. **Network quality matters** - test on WiFi first
5. **Backend must be running** - verify WebSocket server is up

---

## 🆘 Need Help?

If you see errors:
1. Check Xcode console for specific error messages
2. Verify all files were created correctly
3. Make sure Socket.IO dependency is installed
4. Test WebSocket connection first before testing calls

---

**You're almost there! Just wrap your app with AppRootView and test!** 🚀
