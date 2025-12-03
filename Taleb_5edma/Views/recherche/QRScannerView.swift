//
//  QRScannerView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

//
//  QRScannerView.swift
//  Taleb_5edma
//

import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    // Stocke le dernier code QR décodé
    @State private var scannedCode: String?
    // Permet de sélectionner une image existante contenant un QR
    @State private var showingImagePicker = false
    // Affiche une alerte après un scan réussi
    @State private var showingScanResult = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fond de la caméra (simulé)
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Vue caméra simulée
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.primaryRed, lineWidth: 2)
                            )
                        
                        VStack {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 80))
                                .foregroundColor(AppColors.primaryRed)
                            
                            Text("Scanner le code QR")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Résultat du scan
                    if let code = scannedCode {
                        VStack(spacing: 12) {
                            Text("Code scanné:")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(code)
                                .font(.body)
                                .foregroundColor(AppColors.primaryRed)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                        .padding()
                    }
                    
                    // Boutons d'action
                    VStack(spacing: 16) {
                        Button(action: {
                            // Simuler un scan
                            scannedCode = "https://taleb5edma.com/offre/12345"
                            showingScanResult = true
                        }) {
                            Text("Scanner Maintenant")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.primaryRed)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                Text("Choisir depuis la galerie")
                            }
                            .font(.headline)
                            .foregroundColor(AppColors.primaryRed)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Description
                    VStack(spacing: 8) {
                        Text("Scanner un code pour trouver des offres ou informations rapidement.")
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .navigationTitle("Scanner QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                // Ici vous intégrerez un sélecteur d'image réel
                Text("Sélecteur d'image à intégrer")
            }
            .alert("Offre trouvée!", isPresented: $showingScanResult) {
                Button("Voir l'offre") {
                    // Navigation vers l'offre
                }
                Button("Fermer", role: .cancel) { }
            } message: {
                Text("Une offre correspondante a été trouvée. Souhaitez-vous la consulter?")
            }
        }
    }
}

#Preview {
    QRScannerView()
}
