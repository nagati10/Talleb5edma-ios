//
//  QRGeneratorView.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI
import UIKit

/// Interface QR pour prendre une photo ou choisir une image pour générer un code QR
struct QRGeneratorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var qrCodeString: String?
    @State private var showingImageSourceSelection = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGray
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if let qrCodeString = qrCodeString {
                            // Afficher le QR code généré
                            qrCodeDisplay(qrCodeString: qrCodeString)
                        } else if let selectedImage = selectedImage {
                            // Afficher l'image sélectionnée et générer le QR code
                            selectedImageView(image: selectedImage)
                        } else {
                            // Interface de sélection
                            selectionInterface
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Générer QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryRed)
                }
            }
            .confirmationDialog(
                "Choisir une source",
                isPresented: $showingImageSourceSelection,
                titleVisibility: .visible
            ) {
                Button("Caméra") {
                    sourceType = .camera
                    showingImagePicker = true
                }
                
                Button("Galerie") {
                    sourceType = .photoLibrary
                    showingImagePicker = true
                }
                
                Button("Documents") {
                    sourceType = .photoLibrary
                    showingImagePicker = true
                }
                
                Button("Annuler", role: .cancel) { }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                if let image = newValue {
                    generateQRCode(from: image)
                }
            }
        }
    }
    
    // MARK: - Interface de sélection
    
    private var selectionInterface: some View {
        VStack(spacing: 32) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(AppColors.primaryRed)
            
            Text("Générer un QR Code")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.black)
            
            Text("Prenez une photo ou choisissez une image pour générer un code QR")
                .font(.subheadline)
                .foregroundColor(AppColors.mediumGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                Button(action: {
                    showingImageSourceSelection = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Prendre une photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primaryRed)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    sourceType = .photoLibrary
                    showingImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choisir depuis la galerie")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.white)
                    .foregroundColor(AppColors.primaryRed)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.primaryRed, lineWidth: 2)
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Vue de l'image sélectionnée
    
    private func selectedImageView(image: UIImage) -> some View {
        VStack(spacing: 20) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .cornerRadius(12)
                .padding()
                .background(AppColors.white)
                .cornerRadius(16)
            
            if qrCodeString == nil {
                ProgressView("Génération du QR code...")
                    .tint(AppColors.primaryRed)
            }
        }
    }
    
    // MARK: - Affichage du QR code généré
    
    private func qrCodeDisplay(qrCodeString: String) -> some View {
        VStack(spacing: 24) {
            GenericCard {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.successGreen)
                    
                    Text("QR Code généré !")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.black)
                    
                    Text(qrCodeString)
                        .font(.body)
                        .foregroundColor(AppColors.mediumGray)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.backgroundGray)
                        .cornerRadius(8)
                    
                    Button("Copier") {
                        UIPasteboard.general.string = qrCodeString
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.primaryRed)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            Button("Générer un nouveau QR") {
                selectedImage = nil
                self.qrCodeString = nil
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppColors.white)
            .foregroundColor(AppColors.primaryRed)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.primaryRed, lineWidth: 2)
            )
            .cornerRadius(12)
        }
    }
    
    // MARK: - Fonction de génération QR
    
    private func generateQRCode(from image: UIImage) {
        // TODO: Implémenter la génération de QR code à partir de l'image
        // Pour l'instant, on simule
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            qrCodeString = "QR Code généré depuis l'image"
        }
    }
}

#Preview {
    QRGeneratorView()
}

