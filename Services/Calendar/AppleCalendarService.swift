import Foundation
import EventKit

/// Service pour l'intégration avec le calendrier Apple
class AppleCalendarService {
    /// Instance partagée du service
    static let shared = AppleCalendarService()
    
    /// Store de l'EventKit pour accéder aux calendriers
    private let eventStore = EKEventStore()
    
    /// État d'autorisation d'accès au calendrier
    private var calendarAccessAuthorized = false
    
    /// Initialisation privée pour le singleton
    private init() {
        checkCalendarAuthorization()
    }
    
    /// Vérifie l'autorisation d'accès au calendrier
    private func checkCalendarAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .authorized:
            calendarAccessAuthorized = true
        case .notDetermined:
            requestCalendarAccess()
        case .denied, .restricted:
            calendarAccessAuthorized = false
        @unknown default:
            calendarAccessAuthorized = false
        }
    }
    
    /// Demande l'autorisation d'accès au calendrier
    private func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.calendarAccessAuthorized = granted
                
                if let error = error {
                    print("Erreur lors de la demande d'accès au calendrier: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Récupère tous les calendriers disponibles
    /// - Returns: Liste des calendriers
    func fetchCalendars() -> [EKCalendar] {
        guard calendarAccessAuthorized else { return [] }
        
        return eventStore.calendars(for: .event)
    }
    
    /// Récupère les événements pour une période donnée
    /// - Parameters:
    ///   - startDate: Date de début
    ///   - endDate: Date de fin
    ///   - calendars: Calendriers à inclure (tous par défaut)
    ///   - completion: Closure appelée avec les événements ou une erreur
    func fetchEvents(from startDate: Date, to endDate: Date, 
                     in calendars: [EKCalendar]? = nil,
                     completion: @escaping (Result<[EKEvent], Error>) -> Void) {
        guard calendarAccessAuthorized else {
            completion(.failure(CalendarError.notAuthorized))
            return
        }
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        
        completion(.success(events))
    }
    
    /// Crée un nouvel événement dans le calendrier
    /// - Parameters:
    ///   - title: Titre de l'événement
    ///   - startDate: Date de début
    ///   - endDate: Date de fin
    ///   - notes: Notes associées à l'événement
    ///   - calendar: Calendrier dans lequel créer l'événement
    ///   - completion: Closure appelée avec l'événement créé ou une erreur
    func createEvent(title: String, startDate: Date, endDate: Date, 
                     notes: String? = nil, calendar: EKCalendar? = nil,
                     completion: @escaping (Result<EKEvent, Error>) -> Void) {
        guard calendarAccessAuthorized else {
            completion(.failure(CalendarError.notAuthorized))
            return
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        
        if let calendar = calendar {
            event.calendar = calendar
        } else if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
            event.calendar = defaultCalendar
        } else {
            completion(.failure(CalendarError.noDefaultCalendar))
            return
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            completion(.success(event))
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Met à jour un événement existant
    /// - Parameters:
    ///   - event: Événement à mettre à jour
    ///   - completion: Closure appelée avec succès ou erreur
    func updateEvent(_ event: EKEvent, completion: @escaping (Result<Void, Error>) -> Void) {
        guard calendarAccessAuthorized else {
            completion(.failure(CalendarError.notAuthorized))
            return
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Supprime un événement existant
    /// - Parameters:
    ///   - event: Événement à supprimer
    ///   - completion: Closure appelée avec succès ou erreur
    func deleteEvent(_ event: EKEvent, completion: @escaping (Result<Void, Error>) -> Void) {
        guard calendarAccessAuthorized else {
            completion(.failure(CalendarError.notAuthorized))
            return
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Ajoute un rappel à un événement
    /// - Parameters:
    ///   - event: Événement auquel ajouter le rappel
    ///   - alarmOffset: Délai du rappel avant l'événement (en secondes)
    ///   - completion: Closure appelée avec succès ou erreur
    func addAlarmToEvent(_ event: EKEvent, alarmOffset: TimeInterval,
                         completion: @escaping (Result<Void, Error>) -> Void) {
        guard calendarAccessAuthorized else {
            completion(.failure(CalendarError.notAuthorized))
            return
        }
        
        let alarm = EKAlarm(relativeOffset: -alarmOffset)
        event.addAlarm(alarm)
        
        do {
            try eventStore.save(event, span: .thisEvent)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Convertit un événement en modèle CalendarEvent
    /// - Parameter ekEvent: Événement EKEvent à convertir
    /// - Returns: Modèle CalendarEvent
    func convertToCalendarEvent(_ ekEvent: EKEvent) -> CalendarEvent {
        return CalendarEvent(
            id: ekEvent.eventIdentifier,
            title: ekEvent.title ?? "",
            startDate: ekEvent.startDate,
            endDate: ekEvent.endDate,
            isAllDay: ekEvent.isAllDay,
            notes: ekEvent.notes,
            location: ekEvent.location,
            calendarTitle: ekEvent.calendar.title,
            calendarColor: UIColor(cgColor: ekEvent.calendar.cgColor)
        )
    }
}

/// Modèle représentant un événement de calendrier
struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let notes: String?
    let location: String?
    let calendarTitle: String
    let calendarColor: UIColor
    
    /// Durée formatée de l'événement
    var formattedDuration: String {
        if isAllDay {
            return "Toute la journée"
        }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        
        return formatter.string(from: startDate, to: endDate) ?? ""
    }
    
    /// Date formatée pour l'affichage
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = isAllDay ? .none : .short
        
        return formatter.string(from: startDate)
    }
}

/// Erreurs possibles pour le service de calendrier
enum CalendarError: Error {
    case notAuthorized
    case noDefaultCalendar
    case eventNotFound
    case saveFailed
    
    var localizedDescription: String {
        switch self {
        case .notAuthorized:
            return "Accès au calendrier non autorisé"
        case .noDefaultCalendar:
            return "Aucun calendrier par défaut disponible"
        case .eventNotFound:
            return "Événement non trouvé"
        case .saveFailed:
            return "Échec de la sauvegarde de l'événement"
        }
    }
}
