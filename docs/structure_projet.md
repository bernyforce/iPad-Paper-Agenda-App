# Structure du Projet - iPad Paper Agenda App

## Organisation des dossiers

```
iPad_Paper_Agenda_App/
├── PaperAgenda/
│   ├── PaperAgenda/
│   │   ├── App/
│   │   │   ├── AppDelegate.swift
│   │   │   ├── SceneDelegate.swift
│   │   │   └── PaperAgendaApp.swift
│   │   ├── Models/
│   │   │   ├── Page.swift
│   │   │   ├── Notebook.swift
│   │   │   ├── CalendarEvent.swift
│   │   │   ├── UserSettings.swift
│   │   │   └── StrokeData.swift
│   │   ├── Views/
│   │   │   ├── Main/
│   │   │   │   ├── MainView.swift
│   │   │   │   ├── NotebookView.swift
│   │   │   │   └── CalendarView.swift
│   │   │   ├── Page/
│   │   │   │   ├── PageView.swift
│   │   │   │   ├── PageToolbar.swift
│   │   │   │   └── PageTurningView.swift
│   │   │   ├── Drawing/
│   │   │   │   ├── DrawingCanvasView.swift
│   │   │   │   ├── PencilToolsView.swift
│   │   │   │   └── ShapeRecognitionView.swift
│   │   │   ├── Calendar/
│   │   │   │   ├── CalendarIntegrationView.swift
│   │   │   │   ├── EventDetailView.swift
│   │   │   │   └── ReminderView.swift
│   │   │   └── Settings/
│   │   │       ├── SettingsView.swift
│   │   │       ├── TemplateLibraryView.swift
│   │   │       └── CloudSyncSettingsView.swift
│   │   ├── ViewModels/
│   │   │   ├── NotebookViewModel.swift
│   │   │   ├── PageViewModel.swift
│   │   │   ├── DrawingViewModel.swift
│   │   │   ├── CalendarViewModel.swift
│   │   │   └── SettingsViewModel.swift
│   │   ├── Services/
│   │   │   ├── HandwritingRecognition/
│   │   │   │   ├── HandwritingRecognitionService.swift
│   │   │   │   └── TextRecognitionManager.swift
│   │   │   ├── Calendar/
│   │   │   │   ├── AppleCalendarService.swift
│   │   │   │   └── GoogleCalendarService.swift
│   │   │   ├── Cloud/
│   │   │   │   ├── iCloudSyncService.swift
│   │   │   │   └── GoogleDriveSyncService.swift
│   │   │   ├── Media/
│   │   │   │   ├── AudioRecordingService.swift
│   │   │   │   ├── ImageProcessingService.swift
│   │   │   │   └── CameraScanningService.swift
│   │   │   ├── Language/
│   │   │   │   ├── TextToSpeechService.swift
│   │   │   │   ├── TranslationService.swift
│   │   │   │   └── LanguageDetectionService.swift
│   │   │   └── Data/
│   │   │       ├── DataPersistenceService.swift
│   │   │       ├── PDFExportService.swift
│   │   │       └── SharingService.swift
│   │   ├── Utils/
│   │   │   ├── Extensions/
│   │   │   │   ├── UIView+Extensions.swift
│   │   │   │   ├── Date+Extensions.swift
│   │   │   │   └── String+Extensions.swift
│   │   │   ├── Helpers/
│   │   │   │   ├── AnimationHelper.swift
│   │   │   │   ├── NotificationHelper.swift
│   │   │   │   └── PermissionHelper.swift
│   │   │   └── Constants.swift
│   │   ├── Resources/
│   │   │   ├── Assets.xcassets/
│   │   │   ├── Fonts/
│   │   │   ├── Sounds/
│   │   │   ├── Templates/
│   │   │   └── Localizations/
│   │   │       ├── en.lproj/
│   │   │       └── fr.lproj/
│   │   └── Supporting Files/
│   │       ├── Info.plist
│   │       └── PaperAgenda.entitlements
│   ├── PaperAgendaTests/
│   └── PaperAgendaUITests/
└── README.md
```

## Architecture de l'application

### Architecture MVVM

L'application suivra l'architecture MVVM (Model-View-ViewModel) pour séparer clairement les responsabilités :

1. **Models** : Représentent les données et la logique métier
2. **Views** : Responsables de l'affichage et des interactions utilisateur
3. **ViewModels** : Servent d'intermédiaires entre les Models et les Views, contiennent la logique de présentation

### Flux de données

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Services  │◄───┤  ViewModels │◄───┤    Views    │◄───┤ Utilisateur │
└─────┬───────┘    └──────┬──────┘    └─────────────┘    └─────────────┘
      │                   │                  ▲
      │                   │                  │
      │                   ▼                  │
      │            ┌─────────────┐           │
      └───────────►│    Models   ├───────────┘
                   └─────────────┘
```

### Modules principaux

1. **Module de gestion des pages**
   - Responsable de la création, modification et suppression des pages
   - Gère les animations de changement de page
   - Implémente les différents styles de page et modèles

2. **Module de reconnaissance d'écriture**
   - Utilise PencilKit pour capturer l'écriture manuscrite
   - Implémente la reconnaissance d'écriture pour la recherche
   - Gère la conversion entre texte manuscrit et texte numérique

3. **Module d'intégration du calendrier**
   - Connecte l'application aux calendriers Apple et Google
   - Gère la synchronisation des événements
   - Implémente les rappels et notifications

4. **Module de synchronisation cloud**
   - Gère la sauvegarde et la restauration des données
   - Implémente la synchronisation entre appareils
   - Supporte iCloud et Google Drive

5. **Module de traitement d'images et audio**
   - Gère l'enregistrement et la lecture audio
   - Implémente la numérisation de notes avec l'appareil photo
   - Gère l'insertion et le traitement d'images

6. **Module de traduction et détection de langue**
   - Implémente la synthèse vocale
   - Gère la traduction de texte
   - Utilise une API LLM pour la détection automatique de langue

### Interfaces et dépendances

```
┌─────────────────────────────────────────────────────────┐
│                    Interface utilisateur                 │
└───────────┬─────────────────────────────┬───────────────┘
            │                             │
┌───────────▼───────────┐     ┌───────────▼───────────────┐
│  Module de gestion    │     │  Module d'intégration     │
│      des pages        │     │     du calendrier         │
└───────────┬───────────┘     └───────────┬───────────────┘
            │                             │
┌───────────▼───────────┐     ┌───────────▼───────────────┐
│ Module de reconnais-  │     │ Module de synchronisation │
│  sance d'écriture     │     │         cloud             │
└───────────┬───────────┘     └───────────┬───────────────┘
            │                             │
┌───────────▼───────────┐     ┌───────────▼───────────────┐
│ Module de traitement  │     │ Module de traduction et   │
│  d'images et audio    │     │   détection de langue     │
└───────────┬───────────┘     └───────────┬───────────────┘
            │                             │
┌───────────▼─────────────────────────────▼───────────────┐
│                  Services système et APIs                │
└─────────────────────────────────────────────────────────┘
```

## Technologies et frameworks

### Frameworks Apple
- **SwiftUI** : Interface utilisateur principale
- **UIKit** : Fonctionnalités non disponibles dans SwiftUI
- **PencilKit** : Reconnaissance d'écriture et dessin
- **EventKit** : Intégration du calendrier Apple
- **CoreML** : Reconnaissance de formes
- **Vision** : Traitement d'images
- **AVFoundation** : Enregistrement et lecture audio
- **PDFKit** : Génération et manipulation de PDF
- **CloudKit** : Synchronisation iCloud
- **CoreData** : Stockage local des données

### APIs tierces
- **Google Calendar API** : Intégration avec Google Calendar
- **Google Drive API** : Synchronisation cloud alternative
- **API LLM** : Détection de langue et traduction

### Outils de développement
- **Xcode** : Environnement de développement principal
- **Swift Package Manager** : Gestion des dépendances
- **XCTest** : Tests unitaires et d'interface utilisateur
- **Instruments** : Profilage et optimisation des performances
