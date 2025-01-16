import SwiftUI
import PhotosUI
import SwiftOpenAI

struct ContentView: View {
    // MARK: - State Variables
    
    // Stores the list of selected images
    @State private var selectedImages: [UIImage] = []
    // Toggles image picker presentation
    @State private var isImagePickerPresented = false
    // Toggles camera interface presentation
    @State private var isCameraPresented = false
    // Indicates if the images are being processed
    @State private var isProcessing = false
    // Stores alert messages
    @State private var alertMessage: String = ""
    // Toggles the error alert presentation
    @State private var isAlertPresented: Bool = false
    // OpenAI API object initialized with API key from the app's bundle
    @State private var openAI = SwiftOpenAI(apiKey: Bundle.main.getOpenAIApiKey()!)
    // Holds the image to be removed
    @State private var imageToRemove: UIImage? = nil
    // Toggles the alert for image removal confirmation
    @State private var isRemoveAlertPresented = false
    // Tracks the edit mode for reordering images
    @State private var editMode: EditMode = .inactive
    // Stores the URL of the generated PDF
    @State private var generatedPDFURL: URL? = nil
    // Toggles the PDF preview sheet presentation
    @State private var isPDFPreviewPresented: Bool = false
    // Tracks if an image is being dragged
    @GestureState private var isDragging = false
    // Stores the currently dragged image
    @State private var draggedItem: UIImage? = nil
    // Stores the index of the currently dragged image
    @State private var currentIndex: Int? = nil
    // Stores custom requests entered by the user
    @State private var customRequest: String = ""
    
    // Creates an enumerated array of selected images for reordering
    private var enumeratedImages: [(offset: Int, element: UIImage)] {
        Array(selectedImages.enumerated())
    }

    // MARK: - Main View Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.5)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // App Title
                    Text("ClassMate AI")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 5)
                        .padding(.top, 20)
                    
                    ZStack {
                        // Background gradient for the image list section
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .edgesIgnoringSafeArea(.all)
                        
                        // Placeholder text if no images are selected
                        Text("Easily organize your lecture notes by converting your board photos into PDF format")
                            .font(.system(size: 26, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        // Image list displaying selected images
                        List {
                            ForEach(enumeratedImages, id: \.offset) { index, image in
                                HStack {
                                    // Thumbnail of the image
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 160, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                                        .padding(.trailing, 5)
                                    
                                    // Image title and tap-to-remove hint
                                    VStack(alignment: .leading) {
                                        Text("Image \(index + 1)")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Tap to remove")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                .background(Color.clear)
                                .cornerRadius(12)
                                .shadow(color: Color.gray.opacity(0.3), radius: 5, x: 0, y: 5)
                                .onTapGesture {
                                    // Set the selected image to remove
                                    imageToRemove = selectedImages[index]
                                    isRemoveAlertPresented = true
                                }
                            }
                            .onMove { indices, newOffset in
                                // Reorder images in the list
                                selectedImages.move(fromOffsets: indices, toOffset: newOffset)
                            }
                        }
                        .background(Color.clear)
                        .environment(\.editMode, $editMode)
                        .cornerRadius(20)
                    }
                    .cornerRadius(20)
                    
                    // PDF Buttons for previewing or sharing
                    if let pdfURL = generatedPDFURL {
                        HStack(spacing: 10) {
                            // Preview PDF button
                            Button(action: {
                                isPDFPreviewPresented = true
                            }) {
                                Text("Preview\n PDF")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.green]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                            }
                            .sheet(isPresented: $isPDFPreviewPresented) {
                                PDFPreviewView(pdfURL: pdfURL)
                            }
                            
                            // Download/Share PDF button
                            Button(action: {
                                sharePDF(pdfURL: pdfURL)
                            }) {
                                Text("Download/Share PDF")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(LinearGradient(
                                        gradient: Gradient(colors: [Color.red, Color.pink]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                            }
                        }
                    }
                    
                    // Reorder Images Button
                    Button(action: {
                        // Toggle edit mode for reordering
                        editMode = editMode == .active ? .inactive : .active
                    }) {
                        Text(editMode == .active ? "Done" : "Reorder Images")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                    }
                    
                    // Image Picker Button
                    Button(action: { isImagePickerPresented = true }) {
                        Label("Select Images", systemImage: "photo.on.rectangle.angled")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                    }
                    
                    // Camera Button
                    Button(action: { isCameraPresented = true }) {
                        Label("Take Photos", systemImage: "camera")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.orange]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                    }
                    
                    // Custom Request TextField
                    TextField("Type Custom Request (Optional)", text: $customRequest)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                    
                    // Process Images Button
                    Button(action: {
                        isProcessing = true
                        processImagesWithOpenAI()
                    }) {
                        Text("Process Images")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.mint]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                    }
                    .disabled(selectedImages.isEmpty || isProcessing)
                    
                    // Processing Indicator
                    if isProcessing {
                        ProgressView("Processing Images...")
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                            .padding()
                            .scaleEffect(1.6)
                    }
                    
                    Spacer() // Pushes content upwards
                }
                .padding()
                // Image picker modal
                .sheet(isPresented: $isImagePickerPresented) {
                    PhotoPicker(images: $selectedImages)
                }
                // Camera modal
                .fullScreenCover(isPresented: $isCameraPresented) {
                    CameraView(images: $selectedImages)
                }
                // Alert for image removal confirmation
                .alert("Remove Image", isPresented: $isRemoveAlertPresented, actions: {
                    Button("Cancel", role: .cancel) {}
                    Button("Remove", role: .destructive) {
                        if let image = imageToRemove {
                            selectedImages.removeAll { $0 == image }
                        }
                    }
                }, message: {
                    Text("Are you sure you want to remove this image?")
                })
                // General error alert
                .alert(isPresented: $isAlertPresented) {
                    Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
        }
    }
    
    // MARK: - Functions
    
    /// Processes selected images using OpenAI's API.
    func processImagesWithOpenAI() {
        Task {
            var descriptions: [String] = [] // Stores descriptions for all images
            
            do {
                // Iterate over each selected image
                for image in selectedImages {
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
                    let base64Image = imageData.base64EncodedString()
                    let base64ImageData = "data:image/jpeg;base64,\(base64Image)"
                    
                    let userMessage = customRequest.isEmpty ?
                        "Analyze this image and write a detailed description of what is in it. Don't miss any details, I will use your description to create a detailed lecture notes PDF." :
                        customRequest // Use custom text if provided
                    
                    // Send the image to OpenAI for analysis
                    let result = try await openAI.createChatCompletionsWithImageInput(
                        model: .gpt4o(.base),
                        messages: [MessageChatImageInput(
                            text: userMessage,
                            imageURL: base64ImageData,
                            role: .user
                        )],
                        optionalParameters: .init(temperature: 0.5, stop: ["stopstring"], stream: false, maxTokens: 1200)
                    )
                    
                    let description = result?.choices.first?.message.content ?? "No description available"
                    descriptions.append(description)
                }
                
                // Generate a PDF from the descriptions
                if let pdfURL = generatePDF(from: descriptions) {
                    generatedPDFURL = pdfURL
                } else {
                    alertMessage = "Failed to generate PDF."
                    isAlertPresented = true
                }
            } catch {
                // Handle errors during processing
                alertMessage = "Error: \(error.localizedDescription)"
                isAlertPresented = true
            }
            
            isProcessing = false // Reset processing state
        }
    }
    
    /// Generates a PDF file from provided content.
    func generatePDF(from content: [String]) -> URL? {
        let pdfFileName = FileManager.default.temporaryDirectory.appendingPathComponent("LectureNotes.pdf")
        
        // PDF page dimensions and layout settings
        let pageWidth: CGFloat = 612.0 // A4 width
        let pageHeight: CGFloat = 792.0 // A4 height
        let margin: CGFloat = 20.0 // Margins
        let fontSize: CGFloat = 14.0 // Font size
        let lineSpacing: CGFloat = 6.0 // Line spacing
        let titleFontSize: CGFloat = 18.0 // Title font size
        let titleSpacing: CGFloat = 10.0 // Space between title and content

        // Start PDF context
        UIGraphicsBeginPDFContextToFile(pdfFileName.path, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil)
        
        var currentY: CGFloat = margin // Track vertical position
        UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil)
        
        for (index, text) in content.enumerated() {
            // Draw title for each image description
            let title = "Image \(index + 1)"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: titleFontSize),
                .foregroundColor: UIColor.black
            ]
            let titleHeight = title.boundingRect(
                with: CGSize(width: pageWidth - 2 * margin, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: titleAttributes,
                context: nil
            ).height
            
            // Calculate required space
            let requiredSpaceForTitle = currentY + titleHeight + titleSpacing
            let requiredSpaceForContent = requiredSpaceForTitle + text.height(withConstrainedWidth: pageWidth - 2 * margin, font: UIFont.systemFont(ofSize: fontSize)) + lineSpacing
            
            // Add new page if space is insufficient
            if requiredSpaceForContent > pageHeight - margin {
                UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil)
                currentY = margin
            }
            
            // Draw title
            let titleRect = CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: titleHeight)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            currentY += titleHeight + titleSpacing

            // Draw image description
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UIColor.black
            ]
            let attributedText = NSAttributedString(string: text, attributes: textAttributes)
            let textHeight = attributedText.boundingRect(
                with: CGSize(width: pageWidth - 2 * margin, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                context: nil
            ).height
            
            let textRect = CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: textHeight)
            attributedText.draw(in: textRect)
            currentY += textHeight + lineSpacing
        }
        
        UIGraphicsEndPDFContext() // End PDF context
        return pdfFileName
    }
}

extension String {
    /// Helper function to calculate the height of a string with given constraints.
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return boundingBox.height
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]

    func makeUIViewController(context: Context) -> PHPickerViewController {
        // Configure the photo picker
        var config = PHPickerConfiguration()
        config.selectionLimit = 0 // Allow multiple selection
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                        if let image = object as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.images.append(image)
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Shares the generated PDF using the system's share sheet.
func sharePDF(pdfURL: URL) {
    let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
    
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootViewController = windowScene.windows.first?.rootViewController {
        rootViewController.present(activityVC, animated: true, completion: nil)
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var images: [UIImage]

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Append the captured image to the list
            if let image = info[.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    self.parent.images.append(image)
                }
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

extension Array {
    /// Moves elements within the array.
    mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        guard let sourceIndex = source.first,
              sourceIndex < self.count,
              destination <= self.count else {
            print("Invalid source or destination index.")
            return
        }
        
        let item = self[sourceIndex]
        self.remove(at: sourceIndex)
        self.insert(item, at: destination > sourceIndex ? destination - 1 : destination)
    }
}

// SwiftUI preview for ContentView
#Preview {
    ContentView()
}
