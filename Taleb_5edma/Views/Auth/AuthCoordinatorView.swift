
//  AuthCoordinatorView.swift
//  Taleb5edma-cursor
//
//  Created by Apple on 08/11/2025.
//

import SwiftUI

/// Vue coordinatrice qui gère la navigation entre les écrans d'authentification
struct AuthCoordinatorView: View {
    @EnvironmentObject var authService: AuthService
    // Le ViewModel pilote la navigation entre les écrans d'authentification
    @StateObject private var viewModel: LoginViewModel
    
    init() {
        // Initialisation temporaire, sera remplacée par environmentObject
        _viewModel = StateObject(wrappedValue: LoginViewModel())
    }
    
    var body: some View {
        Group {
            switch viewModel.currentScreen {
            case .login:
                LoginView(viewModel: viewModel)
                    .onAppear {
                        viewModel.authService = authService
                    }
            case .signUp:
                SignUpView(viewModel: viewModel)
                    .onAppear {
                        viewModel.authService = authService
                    }
            case .verification:
                VerificationView(viewModel: viewModel)
                    .onAppear {
                        viewModel.authService = authService
                    }
            }
        }
    }
}

#Preview {
    AuthCoordinatorView()
}
