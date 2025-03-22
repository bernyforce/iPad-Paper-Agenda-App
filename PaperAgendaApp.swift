import SwiftUI

@main
struct PaperAgendaApp: App {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var notebookViewModel = NotebookViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(settingsViewModel)
                .environmentObject(notebookViewModel)
                .onAppear {
                    // Configuration initiale de l'application
                    setupAppearance()
                    
                    // Vérification des autorisations nécessaires
                    checkRequiredPermissions()
                }
        }
    }
    
    /// Configure l'apparence globale de l'application
    private func setupAppearance() {
        // Configuration de l'apparence de la barre de navigation
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.white.opacity(0.95))
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configuration de l'apparence des barres d'outils
        let toolbarAppearance = UIToolbarAppearance()
        toolbarAppearance.configureWithOpaqueBackground()
        toolbarAppearance.backgroundColor = UIColor(Color.white.opacity(0.95))
        
        UIToolbar.appearance().standardAppearance = toolbarAppearance
        UIToolbar.appearance().compactAppearance = toolbarAppearance
        UIToolbar.appearance().scrollEdgeAppearance = toolbarAppearance
    }
    
    /// Vérifie et demande les autorisations nécessaires pour l'application
    private func checkRequiredPermissions() {
        // Vérification des autorisations pour le calendrier
        PermissionHelper.checkCalendarPermission { granted in
            if granted {
                print("Autorisation d'accès au calendrier accordée")
            } else {
                print("Autorisation d'accès au calendrier refusée")
            }
        }
        
        // Vérification des autorisations pour les rappels
        PermissionHelper.checkReminderPermission { granted in
            if granted {
                print("Autorisation d'accès aux rappels accordée")
            } else {
                print("Autorisation d'accès aux rappels refusée")
            }
        }
        
        // Vérification des autorisations pour l'appareil photo (si nécessaire)
        PermissionHelper.checkCameraPermission { granted in
            if granted {
                print("Autorisation d'accès à l'appareil photo accordée")
            } else {
                print("Autorisation d'accès à l'appareil photo refusée")
            }
        }
        
        // Vérification des autorisations pour le microphone (si nécessaire)
        PermissionHelper.checkMicrophonePermission { granted in
            if granted {
                print("Autorisation d'accès au microphone accordée")
            } else {
                print("Autorisation d'accès au microphone refusée")
            }
        }
    }
}
