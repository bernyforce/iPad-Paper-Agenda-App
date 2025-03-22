import Foundation

/// Modèle représentant une page de l'agenda
struct Page: Identifiable, Codable {
    /// Identifiant unique de la page
    var id: UUID = UUID()
    
    /// Date associée à la page
    var date: Date
    
    /// Titre de la page (optionnel)
    var title: String?
    
    /// Type de page (jour, semaine, note, etc.)
    var type: PageType
    
    /// Style de papier utilisé pour cette page
    var paperStyle: PaperStyle
    
    /// Données des traits manuscrits (encodées)
    var strokeData: Data?
    
    /// Texte reconnu à partir de l'écriture manuscrite
    var recognizedText: String?
    
    /// Texte numérique saisi directement
    var digitalText: String?
    
    /// Liste des médias associés à la page (images, audio, etc.)
    var mediaAttachments: [MediaAttachment]?
    
    /// Tags associés à la page pour la catégorisation
    var tags: [String]?
    
    /// Date de création de la page
    var createdAt: Date
    
    /// Date de dernière modification de la page
    var updatedAt: Date
    
    /// Initialise une nouvelle page
    /// - Parameters:
    ///   - date: Date associée à la page
    ///   - type: Type de page
    ///   - paperStyle: Style de papier
    init(date: Date = Date(), type: PageType = .day, paperStyle: PaperStyle = .lined) {
        self.date = date
        self.type = type
        self.paperStyle = paperStyle
        self.createdAt = Date()
        self.updatedAt = Date()
        self.mediaAttachments = []
        self.tags = []
    }
    
    /// Ajoute un tag à la page
    /// - Parameter tag: Tag à ajouter
    mutating func addTag(_ tag: String) {
        if tags == nil {
            tags = []
        }
        
        if !tags!.contains(tag) {
            tags!.append(tag)
            updatedAt = Date()
        }
    }
    
    /// Ajoute une pièce jointe média à la page
    /// - Parameter attachment: Pièce jointe à ajouter
    mutating func addMediaAttachment(_ attachment: MediaAttachment) {
        if mediaAttachments == nil {
            mediaAttachments = []
        }
        
        mediaAttachments!.append(attachment)
        updatedAt = Date()
    }
    
    /// Met à jour les données de traits manuscrits
    /// - Parameter data: Nouvelles données de traits
    mutating func updateStrokeData(_ data: Data) {
        self.strokeData = data
        self.updatedAt = Date()
    }
    
    /// Met à jour le texte reconnu
    /// - Parameter text: Nouveau texte reconnu
    mutating func updateRecognizedText(_ text: String) {
        self.recognizedText = text
        self.updatedAt = Date()
    }
}

/// Types de page disponibles
enum PageType: String, Codable, CaseIterable {
    case day
    case week
    case month
    case note
    case todo
    case custom
    
    var displayName: String {
        switch self {
        case .day:
            return "Jour"
        case .week:
            return "Semaine"
        case .month:
            return "Mois"
        case .note:
            return "Note"
        case .todo:
            return "À faire"
        case .custom:
            return "Personnalisé"
        }
    }
}

/// Styles de papier disponibles
enum PaperStyle: String, Codable, CaseIterable {
    case blank
    case lined
    case grid
    case dotted
    case custom
    
    var displayName: String {
        switch self {
        case .blank:
            return "Blanc"
        case .lined:
            return "Ligné"
        case .grid:
            return "Quadrillé"
        case .dotted:
            return "Pointillé"
        case .custom:
            return "Personnalisé"
        }
    }
}

/// Modèle représentant une pièce jointe média
struct MediaAttachment: Identifiable, Codable {
    /// Identifiant unique de la pièce jointe
    var id: UUID = UUID()
    
    /// Type de média
    var type: MediaType
    
    /// URL du fichier média (local ou distant)
    var url: URL
    
    /// Nom du fichier
    var filename: String
    
    /// Taille du fichier en octets
    var size: Int64
    
    /// Date de création
    var createdAt: Date
    
    /// Métadonnées supplémentaires (format JSON)
    var metadata: [String: String]?
    
    /// Initialise une nouvelle pièce jointe média
    /// - Parameters:
    ///   - type: Type de média
    ///   - url: URL du fichier
    ///   - filename: Nom du fichier
    ///   - size: Taille du fichier
    init(type: MediaType, url: URL, filename: String, size: Int64) {
        self.type = type
        self.url = url
        self.filename = filename
        self.size = size
        self.createdAt = Date()
    }
}

/// Types de média supportés
enum MediaType: String, Codable {
    case image
    case audio
    case pdf
    case video
    case other
}
