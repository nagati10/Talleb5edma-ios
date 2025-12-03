# 🔍 Complete Call System Flow Analysis

## 📞 OUTGOING CALL FLOW

### 1. User Initiates Call
**Location:** ChatView → Call Button Click
```
User clicks phone/video icon
↓
ChatViewModel.initiateCall(isVideoCall: Bool)
```

### 2. ChatViewModel Processing
**File:** `ChatViewModel.swift`
```swift
func initiateCall(isVideoCall: Bool) {
    ✓ Checks chatId exists
    ✓ Checks userId exists
    ✓ Sets isVideoCall flag
    ✓ Sets showingCall = true  // ⚠️ POTENTIAL ISSUE HERE
    ✓ Connects to CallManager
    ✓ Calls CallManager.shared.makeCall()
}
```

### 3. CallManager Processing
**File:** `CallManager.swift`
```swift
func makeCall(...) {
    ✓ Creates CallData with roomId
    ✓ Sets callState = .outgoingCall
    ✓ Calls webSocketManager.makeCall()
    ✓ Starts 30-second timeout
}
```

### 4. WebSocket Transmission
**File:** `WebSocketManager.swift`
```swift
func makeCall(...) {
    ✓ Emits 'call-request' event to server
    ✓ Includes: roomId, fromUserId, toUserId, isVideoCall, chatId
}
```

### 5. Server Processing (Backend)
```
Server receives 'call-request'
↓
Finds target user by userId
↓
If target online:
  → Emits 'incoming-call' to target
  → Emits 'call-started' to caller
  → Starts 30s timeout
If target offline:
  → Emits 'call-request-failed' to caller
```

### 6. CallCoordinator Response
**File:** `CallCoordinator.swift`
```swift
Observes callManager.callState
↓
On .outgoingCall:
  ✓ Sets showCallView = true
  ✓ Navigates to CallView via AppRootView
```

### 7. UI Presentation
**⚠️ ISSUE DETECTED:**
```
ChatView shows CallView (via showingCall)
     AND
AppRootView shows CallView (via CallCoordinator)
     =
DUPLICATE CALLVIEWS! ❌
```

---

## 📱 INCOMING CALL FLOW

### 1. WebSocket Event Received
**File:** `WebSocketManager.swift`
```swift
Server emits 'incoming-call'
↓
WebSocketManager.handleIncomingCall()
  ✓ Parses CallData from event
  ✓ Sets callState = .incomingCall(callData)
  ✓ Calls onIncomingCall callback
```

### 2. CallManager Processing
**File:** `CallManager.swift`
```swift
onIncomingCall callback triggered
↓
handleIncomingCall(callData)
  ✓ Stores currentCallData
  ✓ Sets callState = .incomingCall(callData)
  ✓ Starts 30s timeout for answer
```

### 3. CallCoordinator Response
**File:** `CallCoordinator.swift`
```swift
Observes callManager.callState
↓
On .incomingCall(callData):
  ✓ Sets incomingCallData
  ✓ Sets showIncomingCallOverlay = true
```

### 4. UI Presentation
**File:** `AppRootView.swift`
```
if showIncomingCallOverlay:
  ✓ Shows IncomingCallOverlay
  ✓ Displays globally (zIndex: 999)
  ✓ Shows caller name, call type
  ✓ Accept/Decline buttons
```

### 5. User Action - Accept
```
User taps Accept
↓
CallCoordinator.acceptCall()
  ✓ Hides incoming overlay
  ✓ Calls callManager.acceptCall()
  ✓ Sets showCallView = true
  ✓ Navigates to CallView
↓
CallManager.acceptCall()
  ✓ Emits 'call-response' with accepted=true
  ✓ Sets callState = .inCall(callData)
```

### 6. User Action - Reject
```
User taps Reject
↓
CallCoordinator.rejectCall()
  ✓ Calls callManager.rejectCall()
  ✓ Hides overlay
↓
CallManager.rejectCall()
  ✓ Emits 'call-response' with accepted=false
  ✓ Sets callState = .idle
```

### 7. Server Response (After Accept)
```
Server receives 'call-response' (accepted=true)
↓
Server emits 'join-call-room' to BOTH users
  → Contains roomId and callId
↓
Both users join the WebRTC room
```

### 8. Join Room Processing
**File:** `WebSocketManager.swift` → `CallManager.swift`
```swift
WebSocketManager receives 'join-call-room'
↓
Calls onJoinCallRoom callback
↓
CallManager.handleJoinCallRoom()
  ✓ Calls joinCallRoom(roomId)
  ✓ Emits 'join-call' to server
  ✓ Sets callState = .inCall(callData)
```

---

## 🔴 CRITICAL ISSUES FOUND

### Issue #1: Duplicate CallView Presentation
**Problem:**
- ChatView shows CallView via `.fullScreenCover(isPresented: $viewModel.showingCall)`
- AppRootView ALSO shows CallView via `CallCoordinator.showCallView`
- Result: TWO CallViews appear simultaneously

**Solution:**
Remove CallView presentation from ChatView. Let CallCoordinator handle ALL navigation.

**Fix Required:** Update ChatViewModel.initiateCall() to NOT set `showingCall = true`

---

### Issue #2: Hardcoded User ID
**Problem:**
- ChatView passes `toUserId: "company_user_id"` (hardcoded string)
- Calls will fail because server can't find this user

**Solution:**
Extract real user ID from chat/offer data

**Status:** Marked with TODO in code, user must implement

---

### Issue #3: CallView Shown from ChatView
**Problem:**
- ChatView has `.fullScreenCover(isPresented: $viewModel.showingCall)`
- This bypasses the global CallCoordinator system
- Incoming calls won't work if user is in ChatView

**Solution:**
Remove the fullScreenCover from ChatView entirely

---

## ✅ WHAT WORKS CORRECTLY

1. ✅ WebSocket Connection
   - Auto-connects when user logs in
   - Registration with user ID
   - Auto-reconnect on disconnect

2. ✅ Call Request Flow
   - Creates call data
   - Sends to server
   - Server forwards to recipient

3. ✅ Incoming Call Detection
   - Receives WebSocket event
   - Parses call data
   - Triggers overlay

4. ✅ Global Incoming Call Overlay
   - Appears anywhere in app
   - Shows caller info
   - Accept/Decline buttons work

5. ✅ Call State Management
   - State transitions correct
   - Timeout handling (30s)
   - Call ended detection

6. ✅ CallView UI
   - Shows call status
   - Control buttons
   - Auto-dismiss on end

---

## ❌ WHAT DOESN'T WORK YET

1. ❌ Actual Video/Audio Streaming
   - Requires WebRTC implementation
   - Camera/mic are placeholders
   - No peer-to-peer connection

2. ❌ Real Media Controls
   - Toggle video/audio (UI only)
   - Switch camera (placeholder)
   - No actual device control

3. ❌ Background Calls
   - App must be in foreground
   - No VoIP push notifications
   - No CallKit integration

---

## 🔧 REQUIRED FIXES

### Fix #1: Remove Duplicate CallView (CRITICAL)

**File:** `ChatViewModel.swift`
**Change:**
```swift
// BEFORE:
func initiateCall(isVideoCall: Bool) {
    // ...
    self.showingCall = true  // ❌ REMOVE THIS
    // ...
}

// AFTER:
func initiateCall(isVideoCall: Bool) {
    // ...
    // Removed showingCall = true
    // Let CallCoordinator handle navigation
    // ...
}
```

**File:** `ChatView.swift`
**Remove:**
```swift
// ❌ REMOVE THIS ENTIRE BLOCK:
.fullScreenCover(isPresented: $viewModel.showingCall) {
    CallView(...)
}
```

---

### Fix #2: Update Call Initiation

**File:** `ChatViewModel.swift`
**Change:**
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
    
    // ❌ REMOVE: let toUserName = "Company"
    // ❌ REMOVE: let toUserId = "otherUserId"
    // ❌ REMOVE: self.showingCall = true
    
    // Connect to CallManager
    let callManager = CallManager.shared
    
    if !callManager.isConnected {
        let userName = UserDefaults.standard.string(forKey: "userName") ?? "User"
        callManager.connect(userId: userId, userName: userName)
    }
    
    // Get real user info from chat/offer
    let toUserId = offre?.userId ?? "unknown"  // ✅ Get from offre
    let toUserName = offre?.company ?? "Company"  // ✅ Get from offre
    
    // Make the call - CallCoordinator will handle navigation
    callManager.makeCall(
        toUserId: toUserId,
        toUserName: toUserName,
        isVideoCall: isVideoCall,
        chatId: chatId
    )
}
```

---

## 📊 FINAL SYSTEM STATUS

### After Fixes Applied:

**Outgoing Call:**
```
User clicks call button
→ ChatViewModel.initiateCall()
→ CallManager.makeCall()
→ WebSocket sends 'call-request'
→ CallCoordinator detects .outgoingCall state
→ AppRootView shows CallView
→ User sees "Calling..." screen
→ Server forwards to recipient
```

**Incoming Call:**
```
Server sends 'incoming-call' via WebSocket
→ CallManager updates state
→ CallCoordinator detects .incomingCall
→ IncomingCallOverlay appears (ANYWHERE in app)
→ User accepts
→ CallCoordinator shows CallView
→ Both users join room
```

**During Call:**
```
Both users in CallView
→ Can hang up (sends 'end-call')
→ Can toggle controls (UI only, no WebRTC)
→ On hang up: dismisses and notifies other user
```

### Will Work:
✅ Making calls (signaling)
✅ Receiving calls (global popup)
✅ Accept/Reject
✅ Call timeout
✅ Hang up
✅ Call state tracking
✅ UI updates

### Won't Work:
❌ Actual video display
❌ Actual audio transmission
❌ Camera preview
❌ Real mic/speaker

---

## 🎯 CONCLUSION

**Current State:** Almost functional for signaling, broken for navigation

**To Make It Work:**
1. Apply Fix #1 (remove duplicate CallView) - CRITICAL
2. Apply Fix #2 (use real user IDs)
3. Wrap app with AppRootView
4. Test WebSocket connection

**After Fixes:** 
- ✅ Can make and receive call requests
- ✅ Incoming calls popup globally
- ✅ Navigation works correctly
- ✅ Call state management works
- ❌ No actual video/audio (needs WebRTC Phase 3)

**Estimated Time to Fix:** 10-15 minutes
