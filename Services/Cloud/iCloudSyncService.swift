import Foundation
import CloudKit

/// Service pour la synchronisation des données via iCloud
class iCloudSyncService {
    /// Instance partagée du service
    static let shared = iCloudSyncService()
    
    /// Container CloudKit pour l'application
    private let container: CKContainer
    
    /// Base de données privée de l'utilisateur
    private let privateDatabase: CKDatabase
    
    /// Nom de l'enregistrement pour les pages
    private let pageRecordType = "Page"
    
    /// Nom de l'enregistrement pour les carnets
    private let notebookRecordType = "Notebook"
    
    /// Initialisation privée pour le singleton
    private init() {
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
    }
    
    /// Vérifie le statut de connexion iCloud
    /// - Parameter completion: Closure appelée avec le statut de connexion
    func checkiCloudStatus(completion: @escaping (Result<Bool, Error>) -> Void) {
        container.accountStatus { status, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            switch status {
            case .available:
                completion(.success(true))
            case .noAccount, .restricted, .couldNotDetermine:
                completion(.success(false))
            @unknown default:
                completion(.success(false))
            }
        }
    }
    
    /// Sauvegarde une page dans iCloud
    /// - Parameters:
    ///   - page: Page à sauvegarder
    ///   - completion: Closure appelée avec le résultat de l'opération
    func savePage(_ page: Page, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        // Créer un nouvel enregistrement ou récupérer l'existant
        let recordID = CKRecord.ID(recordName: page.id.uuidString)
        
        privateDatabase.fetch(withRecordID: recordID) { record, error in
            let pageRecord: CKRecord
            
            if let error = error as? CKError, error.code == .unknownItem {
                // Créer un nouvel enregistrement
                pageRecord = CKRecord(recordType: self.pageRecordType, recordID: recordID)
            } else if let record = record {
                // Utiliser l'enregistrement existant
                pageRecord = record
            } else if let error = error {
                // Gérer les autres erreurs
                completion(.failure(error))
                return
            } else {
                // Cas improbable, mais gérer quand même
                pageRecord = CKRecord(recordType: self.pageRecordType, recordID: recordID)
            }
            
            // Mettre à jour les champs de l'enregistrement
            do {
                let encoder = JSONEncoder()
                
                // Date associée à la page
                pageRecord["date"] = page.date as CKRecordValue
                
                // Titre de la page
                pageRecord["title"] = page.title as CKRecordValue?
                
                // Type de page
                pageRecord["type"] = page.type.rawValue as CKRecordValue
                
                // Style de papier
                pageRecord["paperStyle"] = page.paperStyle.rawValue as CKRecordValue
                
                // Données des traits manuscrits
                if let strokeData = page.strokeData {
                    let asset = CKAsset(fileURL: self.saveDataToTemporaryFile(data: strokeData, filename: "\(page.id.uuidString)_strokes"))
                    pageRecord["strokeData"] = asset
                }
                
                // Texte reconnu
                pageRecord["recognizedText"] = page.recognizedText as CKRecordValue?
                
                // Texte numérique
                pageRecord["digitalText"] = page.digitalText as CKRecordValue?
                
                // Tags
                if let tags = page.tags {
                    let tagsData = try encoder.encode(tags)
                    pageRecord["tags"] = tagsData as CKRecordValue
                }
                
                // Dates de création et modification
                pageRecord["createdAt"] = page.createdAt as CKRecordValue
                pageRecord["updatedAt"] = page.updatedAt as CKRecordValue
                
                // Sauvegarder l'enregistrement
                self.privateDatabase.save(pageRecord) { record, error in
                    if let error = error {
                        completion(.failure(error))
                    } else if let record = record {
                        completion(.success(record))
                    } else {
                        completion(.failure(CloudSyncError.unknownError))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Récupère toutes les pages depuis iCloud
    /// - Parameter completion: Closure appelée avec les pages récupérées ou une erreur
    func fetchAllPages(completion: @escaping (Result<[Page], Error>) -> Void) {
        let query = CKQuery(recordType: pageRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let pages = records.compactMap { record -> Page? in
                do {
                    return try self.pageFromRecord(record)
                } catch {
                    print("Erreur lors de la conversion d'un enregistrement en page: \(error.localizedDescription)")
                    return nil
                }
            }
            
            completion(.success(pages))
        }
    }
    
    /// Supprime une page d'iCloud
    /// - Parameters:
    ///   - page: Page à supprimer
    ///   - completion: Closure appelée avec le résultat de l'opération
    func deletePage(_ page: Page, completion: @escaping (Result<Void, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: page.id.uuidString)
        
        privateDatabase.delete(withRecordID: recordID) { recordID, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    /// Convertit un enregistrement CKRecord en objet Page
    /// - Parameter record: Enregistrement à convertir
    /// - Returns: Objet Page
    /// - Throws: Erreur en cas de problème de conversion
    private func pageFromRecord(_ record: CKRecord) throws -> Page {
        let decoder = JSONDecoder()
        
        // Récupérer l'ID
        guard let idString = record.recordID.recordName,
              let id = UUID(uuidString: idString) else {
            throw CloudSyncError.invalidRecordFormat
        }
        
        // Récupérer la date
        guard let date = record["date"] as? Date else {
            throw CloudSyncError.invalidRecordFormat
        }
        
        // Récupérer le type de page
        guard let typeString = record["type"] as? String,
              let type = PageType(rawValue: typeString) else {
            throw CloudSyncError.invalidRecordFormat
        }
        
        // Récupérer le style de papier
        guard let paperStyleString = record["paperStyle"] as? String,
              let paperStyle = PaperStyle(rawValue: paperStyleString) else {
            throw CloudSyncError.invalidRecordFormat
        }
        
        // Créer la page
        var page = Page(date: date, type: type, paperStyle: paperStyle)
        page.id = id
        
        // Récupérer le titre
        page.title = record["title"] as? String
        
        // Récupérer les données de traits manuscrits
        if let strokeAsset = record["strokeData"] as? CKAsset,
           let url = strokeAsset.fileURL,
           let strokeData = try? Data(contentsOf: url) {
            page.strokeData = strokeData
        }
        
        // Récupérer le texte reconnu
        page.recognizedText = record["recognizedText"] as? String
        
        // Récupérer le texte numérique
        page.digitalText = record["digitalText"] as? String
        
        // Récupérer les tags
        if let tagsData = record["tags"] as? Data {
            page.tags = try decoder.decode([String].self, from: tagsData)
        }
        
        // Récupérer les dates de création et modification
        if let createdAt = record["createdAt"] as? Date {
            page.createdAt = createdAt
        }
        
        if let updatedAt = record["updatedAt"] as? Date {
            page.updatedAt = updatedAt
        }
        
        return page
    }
    
    /// Sauvegarde des données dans un fichier temporaire
    /// - Parameters:
    ///   - data: Données à sauvegarder
    ///   - filename: Nom du fichier
    /// - Returns: URL du fichier temporaire
    private func saveDataToTemporaryFile(data: Data, filename: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        try? data.write(to: fileURL)
        
        return fileURL
    }
}

/// Erreurs possibles pour la synchronisation cloud
enum CloudSyncError: Error {
    case invalidRecordFormat
    case dataConversionFailed
    case unknownError
    
    var localizedDescription: String {
        switch self {
        case .invalidRecordFormat:
            return "Format d'enregistrement invalide"
        case .dataConversionFailed:
            return "Échec de la conversion des données"
        case .unknownError:
            return "Erreur inconnue lors de la synchronisation"
        }
    }
}
