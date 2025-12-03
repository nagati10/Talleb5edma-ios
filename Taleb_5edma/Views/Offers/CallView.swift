//
//  CallView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

//
//  CallView.swift
//  Taleb_5edma
//

import SwiftUI

struct CallView: View {
    let isVideoCall: Bool
    @Environment(\.dismiss) var dismiss
    // Signalise l'état de la caméra côté utilisateur
    @State private var isVideoOn: Bool
    // Indique si le micro est actif
    @State private var isMicOn = true
    // Indique si le son sort sur le haut-parleur
    @State private var isSpeakerOn = true
    // Affiche l'incrustation de la caméra frontale
    @State private var showSelfView = false
    
    init(isVideoCall: Bool) {
        self.isVideoCall = isVideoCall
        _isVideoOn = State(initialValue: isVideoCall)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Fond d'écran
            Color.gray
                .ignoresSafeArea()
                .blur(radius: isVideoOn ? 0 : 25)
                .overlay(Color.black.opacity(isVideoOn ? 0.3 : 0.6))
            
            VStack(spacing: 0) {
                // Barre du haut
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("10:24")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        Text("Appel en cours...")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button(action: { /* Chat */ }) {
                        Image(systemName: "message")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Info utilisateur (quand vidéo désactivée)
                if !isVideoOn {
                    VStack(spacing: 24) {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Text("MC")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(spacing: 8) {
                            Text("Martha Craig")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("En appel...")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.bottom, 100)
                }
                
                Spacer()
                
                // Contrôles d'appel
                VStack(spacing: 30) {
                    HStack(spacing: 20) {
                        CallControlButton(
                            icon: isVideoOn ? "video.slash.fill" : "video.fill",
                            backgroundColor: isVideoOn ? .white : Color.black.opacity(0.4),
                            contentColor: isVideoOn ? .black : .white
                        ) {
                            withAnimation {
                                isVideoOn.toggle()
                                if isVideoOn {
                                    showSelfView = true
                                } else {
                                    showSelfView = false
                                }
                            }
                        }
                        
                        CallControlButton(
                            icon: isSpeakerOn ? "speaker.wave.2.fill" : "speaker.slash.fill",
                            backgroundColor: isSpeakerOn ? Color.black.opacity(0.4) : .white,
                            contentColor: isSpeakerOn ? .white : .black
                        ) {
                            isSpeakerOn.toggle()
                        }
                        
                        CallControlButton(
                            icon: isMicOn ? "mic.fill" : "mic.slash.fill",
                            backgroundColor: isMicOn ? Color.black.opacity(0.4) : .white,
                            contentColor: isMicOn ? .white : .black
                        ) {
                            isMicOn.toggle()
                        }
                        
                        CallControlButton(
                            icon: "phone.down.fill",
                            backgroundColor: Color(hex: 0xFF3B30),
                            contentColor: .white
                        ) {
                            dismiss()
                        }
                    }
                }
                .padding(.bottom, 50)
            }
            
            // Vue selfie
            if isVideoOn && showSelfView {
                VStack {
                    HStack {
                        Spacer()
                        SelfViewPreview()
                            .frame(width: 100, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                            .padding(.trailing, 20)
                    }
                    Spacer()
                }
                .padding(.top, 100)
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
    }
}

struct SelfViewPreview: View {
    var body: some View {
        ZStack {
            Color.gray
            
            Image(systemName: "person.fill")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct CallControlButton: View {
    let icon: String
    let backgroundColor: Color
    let contentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(contentColor)
                .frame(width: 56, height: 56)
                .background(backgroundColor)
                .clipShape(Circle())
        }
    }
}

#Preview {
    CallView(isVideoCall: true)
}
