import SwiftUI
import PencilKit

/// Vue principale pour l'affichage et l'édition d'une page
struct PageView: View {
    /// ViewModel du carnet contenant la page
    @EnvironmentObject var notebookViewModel: NotebookViewModel
    
    /// ViewModel des paramètres de l'application
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    /// Page à afficher
    @Binding var page: Page
    
    /// État indiquant si la barre d'outils est visible
    @State private var isToolbarVisible = false
    
    /// État indiquant si le mode d'édition est actif
    @State private var isEditMode = true
    
    /// État indiquant si le mode hybride est actif
    @State private var isHybridMode = false
    
    /// Contrôleur de la vue PencilKit
    @State private var pkCanvasController = PKCanvasView.DrawingPolicy.pencilOnly
    
    /// Données du canvas PencilKit
    @State private var canvasData: Data?
    
    /// Gestionnaire de reconnaissance d'écriture
    private let handwritingRecognitionManager = TextRecognitionManager()
    
    var body: some View {
        ZStack {
            // Arrière-plan de la page selon le style de papier
            paperBackground
            
            // Contenu principal
            VStack(spacing: 0) {
                // En-tête de la page
                pageHeader
                
                // Zone de dessin/écriture
                if isHybridMode {
                    // Mode hybride : affichage côte à côte
                    HStack(spacing: 0) {
                        drawingCanvas
                            .frame(width: UIScreen.main.bounds.width / 2)
                        
                        digitalTextEditor
                            .frame(width: UIScreen.main.bounds.width / 2)
                    }
                } else if isEditMode {
                    // Mode édition : canvas de dessin
                    drawingCanvas
                } else {
                    // Mode lecture : texte numérique
                    digitalTextEditor
                }
            }
            
            // Barre d'outils flottante
            if isToolbarVisible {
                pageToolbar
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: isToolbarVisible)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        isToolbarVisible.toggle()
                    }
                }) {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        isEditMode.toggle()
                    }
                }) {
                    Image(systemName: isEditMode ? "doc.text" : "pencil")
                        .font(.title2)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        isHybridMode.toggle()
                    }
                }) {
                    Image(systemName: "rectangle.split.2x1")
                        .font(.title2)
                }
            }
        }
        .onAppear {
            // Charger les données du canvas si disponibles
            canvasData = page.strokeData
        }
        .onDisappear {
            // Sauvegarder les données du canvas
            saveCanvasData()
        }
    }
    
    /// Arrière-plan de la page selon le style de papier
    private var paperBackground: some View {
        Group {
            switch page.paperStyle {
            case .blank:
                Color.white
            case .lined:
                LinedPaperBackground()
            case .grid:
                GridPaperBackground()
            case .dotted:
                DottedPaperBackground()
            case .custom:
                CustomPaperBackground(style: settingsViewModel.customPaperStyle)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    /// En-tête de la page
    private var pageHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Text(formattedDate)
                    .font(.headline)
                
                Spacer()
                
                if let title = page.title {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            if page.type == .day {
                HStack {
                    Text(weekdayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Divider()
        }
    }
    
    /// Canvas de dessin PencilKit
    private var drawingCanvas: some View {
        PencilKitCanvasView(canvasData: $canvasData, drawingPolicy: $pkCanvasController)
            .onChange(of: canvasData) { newValue in
                if let data = newValue {
                    // Mettre à jour les données de traits de la page
                    var updatedPage = page
                    updatedPage.updateStrokeData(data)
                    page = updatedPage
                    
                    // Mettre à jour le ViewModel
                    notebookViewModel.updatePageStrokeData(page, strokeData: data)
                }
            }
    }
    
    /// Éditeur de texte numérique
    private var digitalTextEditor: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let recognizedText = page.recognizedText {
                    Text(recognizedText)
                        .font(.body)
                        .padding()
                        .textSelection(.enabled)
                } else if let digitalText = page.digitalText {
                    Text(digitalText)
                        .font(.body)
                        .padding()
                        .textSelection(.enabled)
                } else {
                    Text("Aucun texte disponible. Utilisez l'Apple Pencil pour écrire ou activez le mode d'édition pour saisir du texte.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
    }
    
    /// Barre d'outils de la page
    private var pageToolbar: some View {
        VStack {
            Spacer()
            
            HStack {
                // Bouton d'impression
                Button(action: {
                    printPage()
                }) {
                    VStack {
                        Image(systemName: "printer")
                            .font(.title2)
                        Text("Imprimer")
                            .font(.caption)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Bouton de partage
                Button(action: {
                    sharePage()
                }) {
                    VStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                        Text("Partager")
                            .font(.caption)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Bouton de conversion de texte
                Button(action: {
                    convertToText()
                }) {
                    VStack {
                        Image(systemName: "text.viewfinder")
                            .font(.title2)
                        Text("Convertir")
                            .font(.caption)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Bouton de surlignage
                Button(action: {
                    toggleHighlightMode()
                }) {
                    VStack {
                        Image(systemName: "highlighter")
                            .font(.title2)
                        Text("Surligner")
                            .font(.caption)
                    }
                    .padding()
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground).opacity(0.9))
            .cornerRadius(15)
            .shadow(radius: 5)
            .padding()
        }
    }
    
    /// Date formatée pour l'affichage
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: page.date)
    }
    
    /// Nom du jour de la semaine
    private var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: page.date)
    }
    
    /// Sauvegarde les données du canvas
    private func saveCanvasData() {
        if let data = canvasData {
            notebookViewModel.updatePageStrokeData(page, strokeData: data)
        }
    }
    
    /// Imprime la page actuelle
    private func printPage() {
        // Logique d'impression à implémenter
        print("Impression de la page")
    }
    
    /// Partage la page actuelle
    private func sharePage() {
        // Logique de partage à implémenter
        print("Partage de la page")
    }
    
    /// Convertit l'écriture manuscrite en texte
    private func convertToText() {
        guard let strokeData = canvasData else { return }
        
        handwritingRecognitionManager.recognizeText(from: strokeData) { result in
            switch result {
            case .success(let recognizedText):
                DispatchQueue.main.async {
                    var updatedPage = page
                    updatedPage.updateRecognizedText(recognizedText)
                    page = updatedPage
                    
                    // Mettre à jour le ViewModel
                    notebookViewModel.updatePageStrokeData(page, strokeData: strokeData)
                }
            case .failure(let error):
                print("Erreur lors de la reconnaissance d'écriture: \(error.localizedDescription)")
            }
        }
    }
    
    /// Active/désactive le mode surlignage
    private func toggleHighlightMode() {
        // Logique de surlignage à implémenter
        print("Basculement du mode surlignage")
    }
}

/// Vue représentant un arrière-plan de papier ligné
struct LinedPaperBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Color.white
                .overlay(
                    VStack(spacing: 0) {
                        ForEach(0..<Int(geometry.size.height / 24), id: \.self) { _ in
                            Rectangle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(height: 1)
                            Spacer()
                                .frame(height: 23)
                        }
                    }
                    .padding(.top, 40) // Espace pour l'en-tête
                )
        }
    }
}

/// Vue représentant un arrière-plan de papier quadrillé
struct GridPaperBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Color.white
                .overlay(
                    ZStack {
                        // Lignes horizontales
                        VStack(spacing: 0) {
                            ForEach(0..<Int(geometry.size.height / 24), id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 1)
                                Spacer()
                                    .frame(height: 23)
                            }
                        }
                        .padding(.top, 40) // Espace pour l'en-tête
                        
                        // Lignes verticales
                        HStack(spacing: 0) {
                            ForEach(0..<Int(geometry.size.width / 24), id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 1)
                                Spacer()
                                    .frame(width: 23)
                            }
                        }
                    }
                )
        }
    }
}

/// Vue représentant un arrière-plan de papier pointillé
struct DottedPaperBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Color.white
                .overlay(
                    ZStack {
                        ForEach(0..<Int(geometry.size.height / 24), id: \.self) { row in
                            ForEach(0..<Int(geometry.size.width / 24), id: \.self) { col in
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 3, height: 3)
                                    .position(x: CGFloat(col * 24), y: CGFloat(row * 24) + 40) // +40 pour l'en-tête
                            }
                        }
                    }
                )
        }
    }
}

/// Vue représentant un arrière-plan de papier personnalisé
struct CustomPaperBackground: View {
    let style: CustomPaperStyle
    
    var body: some View {
        GeometryReader { geometry in
            style.backgroundColor
                .overlay(
                    ZStack {
                        if style.showLines {
                            // Lignes horizontales
                            VStack(spacing: 0) {
                                ForEach(0..<Int(geometry.size.height / CGFloat(style.lineSpacing)), id: \.self) { _ in
                                    Rectangle()
                                        .fill(style.lineColor)
                                        .frame(height: 1)
                                    Spacer()
                                        .frame(height: CGFloat(style.lineSpacing) - 1)
                                }
                            }
                            .padding(.top, 40) // Espace pour l'en-tête
                        }
                        
                        if style.showGrid {
                            // Lignes verticales
                            HStack(spacing: 0) {
                                ForEach(0..<Int(geometry.size.width / CGFloat(style.gridSpacing)), id: \.self) { _ in
                                    Rectangle()
                                        .fill(style.lineColor)
                                        .frame(width: 1)
                                    Spacer()
                                        .frame(width: CGFloat(style.gridSpacing) - 1)
                                }
                            }
                        }
                        
                        if style.showDots {
                            ForEach(0..<Int(geometry.size.height / CGFloat(style.dotSpacing)), id: \.self) { row in
                                ForEach(0..<Int(geometry.size.width / CGFloat(style.dotSpacing)), id: \.self) { col in
                                    Circle()
                                        .fill(style.dotColor)
                                        .frame(width: CGFloat(style.dotSize), height: CGFloat(style.dotSize))
                                        .position(
                                            x: CGFloat(col * style.dotSpacing),
                                            y: CGFloat(row * style.dotSpacing) + 40 // +40 pour l'en-tête
                                        )
                                }
                            }
                        }
                    }
                )
        }
    }
}

/// Structure représentant un style de papier personnalisé
struct CustomPaperStyle {
    var backgroundColor: Color = .white
    var lineColor: Color = Color.blue.opacity(0.2)
    var dotColor: Color = Color.gray.opacity(0.3)
    var showLines: Bool = true
    var showGrid: Bool = false
    var showDots: Bool = false
    var lineSpacing: Int = 24
    var gridSpacing: Int = 24
    var dotSpacing: Int = 24
    var dotSize: Int = 3
}

/// Vue représentant un canvas PencilKit
struct PencilKitCanvasView: UIViewRepresentable {
    @Binding var canvasData: Data?
    @Binding var drawingPolicy: PKCanvasView.DrawingPolicy
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawingPolicy = drawingPolicy
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 1)
        canvasView.delegate = context.coordinator
        
        // Charger les données du canvas si disponibles
        if let data = canvasData {
            do {
                let drawing = try PKDrawing(data: data)
                canvasView.drawing = drawing
            } catch {
                print("Erreur lors du chargement du dessin: \(error.localizedDescription)")
            }
        }
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Mettre à jour la politique de dessin si nécessaire
        if uiView.drawingPolicy != drawingPolicy {
            uiView.drawingPolicy = drawingPolicy
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilKitCanvasView
        
        init(_ parent: PencilKitCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Sauvegarder les données du dessin lorsqu'il change
            parent.canvasData = canvasView.drawing.dataRepresentation()
        }
    }
}
