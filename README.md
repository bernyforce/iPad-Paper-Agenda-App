# iPad Paper Agenda App - README

## Description

iPad Paper Agenda est une application native iOS conçue pour simuler un agenda papier réel tout en tirant parti des fonctionnalités avancées de l'iPad et de l'Apple Pencil. L'application offre une expérience d'écriture manuscrite naturelle combinée à des fonctionnalités numériques avancées comme la reconnaissance d'écriture, l'intégration du calendrier, et diverses fonctionnalités multimédias.

## Fonctionnalités principales

- **Simulation d'agenda papier** : Interface mimant un agenda physique avec animations réalistes pour le changement de page
- **Écriture naturelle avec Apple Pencil** : Capture précise de l'écriture manuscrite avec latence minimale
- **Reconnaissance d'écriture manuscrite** : Recherche dans le contenu manuscrit grâce à la reconnaissance d'écriture
- **Pages personnalisables** : Différents styles de papier (ligné, quadrillé, pointillé, blanc)
- **Mode hybride** : Basculement entre versions manuscrite et numérique d'une même page
- **Intégration du calendrier** : Connexion avec Apple Calendar et Google Calendar
- **Synchronisation cloud** : Sauvegarde et synchronisation via iCloud ou Google Drive
- **Fonctionnalités avancées** : Enregistrement audio, insertion d'images, reconnaissance de formes, etc.

## Structure du projet

```
iPad_Paper_Agenda_App/
├── PaperAgenda/
│   ├── App/
│   │   ├── AppDelegate.swift
│   │   ├── SceneDelegate.swift
│   │   └── PaperAgendaApp.swift
│   ├── Models/
│   │   ├── Page.swift
│   │   ├── Notebook.swift
│   │   └── ...
│   ├── Views/
│   │   ├── Main/
│   │   ├── Page/
│   │   ├── Drawing/
│   │   └── ...
│   ├── ViewModels/
│   │   ├── NotebookViewModel.swift
│   │   ├── PageViewModel.swift
│   │   └── ...
│   ├── Services/
│   │   ├── HandwritingRecognition/
│   │   ├── Calendar/
│   │   ├── Cloud/
│   │   └── ...
│   └── Utils/
│       ├── Extensions/
│       ├── Helpers/
│       └── ...
```

## Prérequis techniques

- Xcode 14.0 ou supérieur
- iOS 15.0 ou supérieur
- iPad compatible avec Apple Pencil
- Compte développeur Apple (pour le déploiement)

## Installation

1. Clonez ce dépôt
2. Ouvrez le fichier `PaperAgenda.xcodeproj` dans Xcode
3. Configurez votre identifiant d'équipe de développement dans les paramètres du projet
4. Compilez et exécutez l'application sur votre iPad

## Documentation

La documentation complète du projet est disponible dans le dossier `docs/` :

- `analyse_exigences.md` : Analyse détaillée des exigences
- `structure_projet.md` : Structure et architecture du projet
- `specification_application.md` : Spécification complète de l'application
- `documentation_code.md` : Documentation des sections clés du code

## Fonctionnalités principales expliquées

### Reconnaissance d'écriture manuscrite

L'application utilise PencilKit pour capturer l'écriture manuscrite et Vision pour la reconnaissance de texte. Le processus se déroule en plusieurs étapes :

1. Capture des traits avec PencilKit
2. Conversion des traits en image
3. Reconnaissance de texte avec Vision
4. Indexation du texte reconnu pour la recherche

### Intégration du calendrier

L'intégration avec les calendriers Apple et Google est réalisée via EventKit et l'API Google Calendar. Les fonctionnalités incluent :

- Affichage des événements existants
- Création de nouveaux événements
- Ajout de notes manuscrites aux événements
- Configuration de rappels et notifications

### Synchronisation cloud

La synchronisation des données est gérée via CloudKit (iCloud) ou l'API Google Drive. Les mécanismes incluent :

- Synchronisation automatique en arrière-plan
- Gestion des conflits
- Stockage efficace des données volumineuses

## Contribution

Les contributions sont les bienvenues ! Pour contribuer :

1. Forkez le projet
2. Créez une branche pour votre fonctionnalité (`git checkout -b feature/amazing-feature`)
3. Committez vos changements (`git commit -m 'Add some amazing feature'`)
4. Poussez vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrez une Pull Request

## Licence

Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.

## Contact

Pour toute question ou suggestion, n'hésitez pas à ouvrir une issue sur ce dépôt.
