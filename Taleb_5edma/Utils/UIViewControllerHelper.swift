//
//  UIViewControllerHelper.swift
//  Taleb5edma-cursor
//
//  Created by Apple on 08/11/2025.
//

import SwiftUI
import UIKit

/// Helper pour obtenir le UIViewController depuis une SwiftUI View
extension View {
    /// Récupère le UIViewController qui présente cette vue
    func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return nil
        }
        return rootViewController
    }
    
    /// Récupère le UIViewController le plus haut dans la hiérarchie
    func getTopViewController() -> UIViewController? {
        guard let rootViewController = getRootViewController() else {
            return nil
        }
        
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        
        // Si c'est un UINavigationController, prendre le topViewController
        if let navigationController = topViewController as? UINavigationController {
            topViewController = navigationController.topViewController ?? topViewController
        }
        
        return topViewController
    }
}

