//
//  ImagePicker.swift
//  Taleb_5edma
//
//  Created by Apple on 10/11/2025.
//

import SwiftUI
import PhotosUI

// MARK: - ImagePicker

/// Composant SwiftUI wrapper pour `UIImagePickerController` permettant de sélectionner
/// une image depuis la galerie photo ou l'appareil photo de l'iPhone
///
/// **Fonctionnalités:**
/// - Sélection d'image depuis la galerie photo
/// - Capture d'image depuis l'appareil photo (si disponible)
/// - Édition de l'image avant sélection (cropping)
/// - Support de l'annulation par l'utilisateur
///
/// **Utilisation:**
/// ```swift
/// @State private var selectedImage: UIImage?
/// @State private var showImagePicker = false
///
/// .sheet(isPresented: $showImagePicker) {
///     ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
/// }
/// ```
///
/// **Note:**
/// Nécessite d'ajouter les clés `NSPhotoLibraryUsageDescription` et `NSCameraUsageDescription`
/// dans `Info.plist` pour demander les permissions appropriées
struct ImagePicker: UIViewControllerRepresentable {
    // MARK: - Properties
    
    /// Binding vers l'image sélectionnée par l'utilisateur
    /// Mise à jour automatiquement quand l'utilisateur sélectionne une image
    @Binding var selectedImage: UIImage?
    
    /// Ferme le picker quand appelé
    @Environment(\.dismiss) var dismiss
    
    /// Source de l'image à utiliser (galerie ou caméra)
    /// Par défaut: `.photoLibrary` pour la galerie photo
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    // MARK: - UIViewControllerRepresentable Methods
    
    /// Crée et configure le UIImagePickerController
    /// Configure la source (galerie/caméra), le délégué et permet l'édition
    /// - Parameter context: Le contexte de représentation SwiftUI
    /// - Returns: Le UIImagePickerController configuré
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true // Permet l'édition (cropping) de l'image
        return picker
    }
    
    /// Appelé quand la vue SwiftUI change (non utilisé ici)
    /// - Parameters:
    ///   - uiViewController: Le UIImagePickerController
    ///   - context: Le contexte de représentation SwiftUI
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    /// Crée le coordinateur pour gérer les événements du UIImagePickerController
    /// - Returns: Une instance de Coordinator configurée
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    /// Coordinateur pour gérer les événements du UIImagePickerController
    /// Implémente `UIImagePickerControllerDelegate` pour recevoir les sélections d'image
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        /// Référence au parent ImagePicker pour mettre à jour le binding
        let parent: ImagePicker
        
        /// Initialise le coordinateur avec une référence au parent
        /// - Parameter parent: L'instance ImagePicker parente
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        /// Appelé quand l'utilisateur sélectionne une image
        /// Priorise l'image éditée (croppée) si disponible, sinon utilise l'originale
        /// - Parameters:
        ///   - picker: Le UIImagePickerController
        ///   - info: Dictionnaire contenant les informations de l'image sélectionnée
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Prioriser l'image éditée (si l'utilisateur a croppé)
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                // Sinon, utiliser l'image originale
                parent.selectedImage = originalImage
            }
            // Fermer le picker après sélection
            parent.dismiss()
        }
        
        /// Appelé quand l'utilisateur annule la sélection
        /// Ferme simplement le picker sans mettre à jour l'image
        /// - Parameter picker: Le UIImagePickerController
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - ImageSourcePicker

/// Vue helper pour afficher un ActionSheet permettant de choisir la source de l'image
/// Permet à l'utilisateur de choisir entre la caméra ou la galerie photo
///
/// **Fonctionnalités:**
/// - ActionSheet avec options "Caméra" et "Galerie"
/// - Vérifie la disponibilité de la caméra avant de proposer cette option
/// - Affiche le ImagePicker avec la source appropriée selon le choix de l'utilisateur
///
/// **Utilisation:**
/// ```swift
/// @State private var selectedImage: UIImage?
///
/// ImageSourcePicker(selectedImage: $selectedImage)
/// ```
///
/// **Note:**
/// Cette vue est utilisée dans `ProfileView` et `CreateOfferView` pour permettre
/// à l'utilisateur de choisir entre prendre une photo ou sélectionner depuis la galerie
struct ImageSourcePicker: View {
    // MARK: - Properties
    
    /// Binding vers l'image sélectionnée par l'utilisateur
    @Binding var selectedImage: UIImage?
    
    /// Indique si le ImagePicker doit être affiché
    @State private var showImagePicker = false
    
    /// Indique si l'ActionSheet doit être affiché
    @State private var showActionSheet = false
    
    /// Source de l'image sélectionnée par l'utilisateur (caméra ou galerie)
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        Button(action: {
            showActionSheet = true
        }) {
            EmptyView()
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text("Choisir une photo"),
                buttons: [
                    .default(Text("Caméra")) {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            sourceType = .camera
                            showImagePicker = true
                        }
                    },
                    .default(Text("Galerie")) {
                        sourceType = .photoLibrary
                        showImagePicker = true
                    },
                    .cancel(Text("Annuler"))
                ]
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
        }
    }
}

