import Foundation
import PencilKit
import Vision

/// Service pour la reconnaissance d'écriture manuscrite
class HandwritingRecognitionService {
    /// Instance partagée du service
    static let shared = HandwritingRecognitionService()
    
    /// Initialisation privée pour le singleton
    private init() {}
    
    /// Reconnaît le texte à partir des données de traits manuscrits
    /// - Parameters:
    ///   - strokeData: Données des traits manuscrits (PKDrawing)
    ///   - completion: Closure appelée avec le texte reconnu ou une erreur
    func recognizeText(from strokeData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            // Convertir les données en PKDrawing
            let drawing = try PKDrawing(data: strokeData)
            
            // Créer une image à partir du dessin
            let image = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
            
            // Utiliser Vision pour la reconnaissance de texte
            recognizeTextInImage(image) { result in
                completion(result)
            }
        } catch {
            completion(.failure(HandwritingRecognitionError.invalidStrokeData))
        }
    }
    
    /// Reconnaît le texte dans une image
    /// - Parameters:
    ///   - image: Image contenant du texte manuscrit
    ///   - completion: Closure appelée avec le texte reconnu ou une erreur
    private func recognizeTextInImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(HandwritingRecognitionError.invalidImage))
            return
        }
        
        // Créer une requête de reconnaissance de texte
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(HandwritingRecognitionError.noTextFound))
                return
            }
            
            // Extraire le texte reconnu de chaque observation
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            if recognizedText.isEmpty {
                completion(.failure(HandwritingRecognitionError.noTextFound))
            } else {
                completion(.success(recognizedText))
            }
        }
        
        // Configurer la requête pour la reconnaissance d'écriture manuscrite
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Exécuter la requête de reconnaissance
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }
}

/// Gestionnaire de reconnaissance de texte
class TextRecognitionManager {
    /// Service de reconnaissance d'écriture
    private let handwritingRecognitionService = HandwritingRecognitionService.shared
    
    /// Reconnaît le texte à partir des données de traits manuscrits
    /// - Parameters:
    ///   - strokeData: Données des traits manuscrits
    ///   - completion: Closure appelée avec le texte reconnu ou une erreur
    func recognizeText(from strokeData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        handwritingRecognitionService.recognizeText(from: strokeData, completion: completion)
    }
    
    /// Recherche un texte spécifique dans les données de traits manuscrits
    /// - Parameters:
    ///   - searchText: Texte à rechercher
    ///   - strokeData: Données des traits manuscrits
    ///   - completion: Closure appelée avec un booléen indiquant si le texte a été trouvé
    func searchText(_ searchText: String, in strokeData: Data, completion: @escaping (Bool) -> Void) {
        handwritingRecognitionService.recognizeText(from: strokeData) { result in
            switch result {
            case .success(let recognizedText):
                let found = recognizedText.lowercased().contains(searchText.lowercased())
                completion(found)
            case .failure:
                completion(false)
            }
        }
    }
}

/// Erreurs possibles pour la reconnaissance d'écriture
enum HandwritingRecognitionError: Error {
    case invalidStrokeData
    case invalidImage
    case noTextFound
    case processingFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidStrokeData:
            return "Données de traits manuscrits invalides"
        case .invalidImage:
            return "Image invalide pour la reconnaissance"
        case .noTextFound:
            return "Aucun texte trouvé dans l'image"
        case .processingFailed:
            return "Échec du traitement de la reconnaissance"
        }
    }
}
