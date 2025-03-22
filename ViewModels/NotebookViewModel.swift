import Foundation
import Combine

/// ViewModel pour la gestion d'un carnet de notes/agenda
class NotebookViewModel: ObservableObject {
    /// Liste des pages du carnet
    @Published var pages: [Page] = []
    
    /// Page actuellement sélectionnée
    @Published var selectedPage: Page?
    
    /// Index de la page actuellement affichée
    @Published var currentPageIndex: Int = 0
    
    /// Service de persistance des données
    private let dataPersistenceService = DataPersistenceService()
    
    /// Service de reconnaissance d'écriture
    private let handwritingRecognitionService = HandwritingRecognitionService()
    
    /// Cancellables pour la gestion des abonnements Combine
    private var cancellables = Set<AnyCancellable>()
    
    /// Initialise le ViewModel du carnet
    init() {
        loadPages()
        setupSubscriptions()
    }
    
    /// Configure les abonnements aux changements
    private func setupSubscriptions() {
        // Observer les changements de pages pour sauvegarder automatiquement
        $pages
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] pages in
                self?.savePages()
            }
            .store(in: &cancellables)
    }
    
    /// Charge les pages depuis le stockage persistant
    func loadPages() {
        dataPersistenceService.loadPages { [weak self] result in
            switch result {
            case .success(let loadedPages):
                DispatchQueue.main.async {
                    self?.pages = loadedPages
                    if !loadedPages.isEmpty && self?.selectedPage == nil {
                        self?.selectedPage = loadedPages[0]
                        self?.currentPageIndex = 0
                    }
                }
            case .failure(let error):
                print("Erreur lors du chargement des pages: \(error.localizedDescription)")
                // Créer quelques pages par défaut si le chargement échoue
                self?.createDefaultPages()
            }
        }
    }
    
    /// Sauvegarde les pages dans le stockage persistant
    func savePages() {
        dataPersistenceService.savePages(pages) { result in
            switch result {
            case .success:
                print("Pages sauvegardées avec succès")
            case .failure(let error):
                print("Erreur lors de la sauvegarde des pages: \(error.localizedDescription)")
            }
        }
    }
    
    /// Crée des pages par défaut pour un nouveau carnet
    private func createDefaultPages() {
        let today = Date()
        let calendar = Calendar.current
        
        // Créer une page pour aujourd'hui
        let todayPage = Page(date: today, type: .day, paperStyle: .lined)
        
        // Créer une page pour la semaine en cours
        var weekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        if let startOfWeek = calendar.date(from: weekComponents) {
            let weekPage = Page(date: startOfWeek, type: .week, paperStyle: .grid)
            
            // Créer une page pour le mois en cours
            var monthComponents = DateComponents()
            monthComponents.year = calendar.component(.year, from: today)
            monthComponents.month = calendar.component(.month, from: today)
            monthComponents.day = 1
            
            if let startOfMonth = calendar.date(from: monthComponents) {
                let monthPage = Page(date: startOfMonth, type: .month, paperStyle: .dotted)
                
                // Créer une page de notes vierge
                let notePage = Page(date: today, type: .note, paperStyle: .blank)
                
                // Ajouter toutes les pages
                DispatchQueue.main.async {
                    self.pages = [todayPage, weekPage, monthPage, notePage]
                    self.selectedPage = todayPage
                    self.currentPageIndex = 0
                    self.savePages()
                }
            }
        }
    }
    
    /// Ajoute une nouvelle page au carnet
    /// - Parameters:
    ///   - type: Type de page
    ///   - paperStyle: Style de papier
    ///   - date: Date associée à la page
    func addPage(type: PageType, paperStyle: PaperStyle, date: Date = Date()) {
        let newPage = Page(date: date, type: type, paperStyle: paperStyle)
        pages.append(newPage)
        selectedPage = newPage
        currentPageIndex = pages.count - 1
    }
    
    /// Supprime une page du carnet
    /// - Parameter page: Page à supprimer
    func deletePage(_ page: Page) {
        if let index = pages.firstIndex(where: { $0.id == page.id }) {
            pages.remove(at: index)
            
            // Mettre à jour la page sélectionnée si nécessaire
            if selectedPage?.id == page.id {
                if !pages.isEmpty {
                    let newIndex = min(index, pages.count - 1)
                    selectedPage = pages[newIndex]
                    currentPageIndex = newIndex
                } else {
                    selectedPage = nil
                    currentPageIndex = 0
                }
            } else if let selectedPage = selectedPage, let selectedIndex = pages.firstIndex(where: { $0.id == selectedPage.id }) {
                currentPageIndex = selectedIndex
            }
        }
    }
    
    /// Navigue vers la page suivante
    func nextPage() {
        if currentPageIndex < pages.count - 1 {
            currentPageIndex += 1
            selectedPage = pages[currentPageIndex]
        }
    }
    
    /// Navigue vers la page précédente
    func previousPage() {
        if currentPageIndex > 0 {
            currentPageIndex -= 1
            selectedPage = pages[currentPageIndex]
        }
    }
    
    /// Met à jour les données de traits manuscrits d'une page
    /// - Parameters:
    ///   - page: Page à mettre à jour
    ///   - strokeData: Nouvelles données de traits
    func updatePageStrokeData(_ page: Page, strokeData: Data) {
        if let index = pages.firstIndex(where: { $0.id == page.id }) {
            var updatedPage = pages[index]
            updatedPage.updateStrokeData(strokeData)
            pages[index] = updatedPage
            
            // Mettre à jour la page sélectionnée si nécessaire
            if selectedPage?.id == page.id {
                selectedPage = updatedPage
            }
            
            // Lancer la reconnaissance d'écriture en arrière-plan
            recognizeHandwriting(for: updatedPage)
        }
    }
    
    /// Lance la reconnaissance d'écriture pour une page
    /// - Parameter page: Page à analyser
    private func recognizeHandwriting(for page: Page) {
        guard let strokeData = page.strokeData else { return }
        
        handwritingRecognitionService.recognizeText(from: strokeData) { [weak self] result in
            switch result {
            case .success(let recognizedText):
                DispatchQueue.main.async {
                    if let index = self?.pages.firstIndex(where: { $0.id == page.id }) {
                        var updatedPage = self?.pages[index]
                        updatedPage?.updateRecognizedText(recognizedText)
                        
                        if let updatedPage = updatedPage {
                            self?.pages[index] = updatedPage
                            
                            // Mettre à jour la page sélectionnée si nécessaire
                            if self?.selectedPage?.id == page.id {
                                self?.selectedPage = updatedPage
                            }
                        }
                    }
                }
            case .failure(let error):
                print("Erreur lors de la reconnaissance d'écriture: \(error.localizedDescription)")
            }
        }
    }
    
    /// Recherche des pages contenant un texte spécifique
    /// - Parameter searchText: Texte à rechercher
    /// - Returns: Liste des pages correspondant à la recherche
    func searchPages(containing searchText: String) -> [Page] {
        guard !searchText.isEmpty else { return [] }
        
        return pages.filter { page in
            // Rechercher dans le texte reconnu
            if let recognizedText = page.recognizedText, 
               recognizedText.lowercased().contains(searchText.lowercased()) {
                return true
            }
            
            // Rechercher dans le texte numérique
            if let digitalText = page.digitalText,
               digitalText.lowercased().contains(searchText.lowercased()) {
                return true
            }
            
            // Rechercher dans le titre
            if let title = page.title,
               title.lowercased().contains(searchText.lowercased()) {
                return true
            }
            
            // Rechercher dans les tags
            if let tags = page.tags,
               tags.contains(where: { $0.lowercased().contains(searchText.lowercased()) }) {
                return true
            }
            
            return false
        }
    }
}
