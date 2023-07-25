//
//  StoryView.swift
//  WonderSproutsApp
//
//  Created by Charles Atchison on 7/21/23.
//

import SwiftUI
import AVFoundation

struct WordData: Codable, Identifiable {
    var id: Int { pageNum }
    var pageNum: Int
    var wordNum: Int
    var word: String
    var sec: Double
}

class ViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    
    // Variables for managing current word data and all word data from JSON
    @Published var currentWord: WordData?
    @Published var words: [WordData] = []
    // Timer to stop the audio at the correct time
    var stopAudioTimer: Timer?
    // Tracks the last word that was highlighted in the text
    @Published var lastHighlightedWordIndex: Int? = nil
    // Base font size for the display text
    let baseFontSize: CGFloat = 30
    // Store the time where the audio was paused to resume from the same time
    var lastPausedTime: Double?

    // Current page in the story
    var currentPage = 1 {
        didSet {
            handlePageTransition() // Handle tasks required when transitioning to a new page
            currentWord = nil
        }
    }

    // Audio player to play the story's audio
    var audioPlayer: AVAudioPlayer?
    // Variable to determine if the audio is currently playing
    @Published var isPlaying = false
    // Variable to track the current word being highlighted
    @Published var highlightedWordNum = 0
    // Array to hold timings for highlighting words
    var highlightTimings: [(NSRange, Double)] = []
    // Current range of text that is highlighted
    @Published var currentHighlightedRange: NSRange = NSRange(location: 0, length: 0)
    
    // Timer used for word highlighting
    var timer: Timer?
    
    // Store the last time a button was pressed to avoid multiple quick presses
    var lastButtonPressTime = Date().addingTimeInterval(-1) // Initialize with a past time

    // Check if enough time has passed since the last button press
    func isButtonPressAllowed() -> Bool {
        let currentTime = Date()
        if currentTime.timeIntervalSince(lastButtonPressTime) > 0.5 { // 0.5 second debounce time
            lastButtonPressTime = currentTime
            return true
        }
        return false
    }

    override init() {
        super.init()
        loadJSON() // Load word data from JSON
        setupAudio() // Setup audio player
    }
    
    // Load word data from JSON file
    func loadJSON() {
        guard let url = Bundle.main.url(forResource: "combined_story_female", withExtension: "json") else {
            print("Failed to find the JSON resource.")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            words = try JSONDecoder().decode([WordData].self, from: data)
        } catch {
            print("Error decoding JSON: \(error)")
        }
    }
    
    // Setup the audio player for the story
    func setupAudio() {
        guard let audioURL = Bundle.main.url(forResource: "combined_story_female", withExtension: "mp3") else {
            print("Failed to find the audio resource.")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
        } catch {
            print("Error setting up audio: \(error)")
        }
    }

    /// Generates an attributed string where a specific word in the text is highlighted.
        func getAttributedText(for text: String) -> NSAttributedString {
            let attributedString = NSMutableAttributedString(string: text)
            let baseFont = UIFont.systemFont(ofSize: baseFontSize)
            let highlightedFont = UIFont.systemFont(ofSize: baseFontSize + 5) // Highlighted words will appear 5 font points larger than the rest
            
            // Apply default font and color for the entire string
            attributedString.addAttribute(.font, value: baseFont, range: NSRange(location: 0, length: text.count))
            attributedString.addAttribute(.foregroundColor, value: UIColor(named: "textColor")!, range: NSRange(location: 0, length: text.count))
            
            // Apply special font and color for the currently highlighted word
            attributedString.addAttribute(.foregroundColor, value: UIColor.yellow, range: currentHighlightedRange)
            attributedString.addAttribute(.font, value: highlightedFont, range: currentHighlightedRange)

            return attributedString
        }
    
    /// Initiates the process of highlighting words in sync with the audio playback.
        func startHighlighting() {
            timer?.invalidate()  // Ensure any existing timer is terminated before creating a new one
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let audioPlayer = self.audioPlayer else { return }
                
                // Filter words that belong to the current page only
                let wordsForCurrentPage = self.words.filter { $0.pageNum == self.currentPage }
                var wordIndexInText = 0
                    
                // Loop through words and check if the audio's current playtime matches the word's designated highlight timing
                for (index, wordData) in wordsForCurrentPage.enumerated() {
                    let wordLength = wordData.word.count
                    if let nextWord = wordsForCurrentPage.first(where: { $0.wordNum > wordData.wordNum }) {
                        if audioPlayer.currentTime >= wordData.sec && audioPlayer.currentTime < nextWord.sec {
                            self.currentHighlightedRange = NSRange(location: wordIndexInText, length: wordLength)
                            self.lastHighlightedWordIndex = index
                            break
                        }
                    } else if audioPlayer.currentTime >= wordData.sec {
                        self.currentHighlightedRange = NSRange(location: wordIndexInText, length: wordLength)
                        self.lastHighlightedWordIndex = index
                        // If the last word in the current page is reached, stop audio playback after a delay
                        if index == wordsForCurrentPage.count - 1 && audioPlayer.currentTime >= wordData.sec + 1.0 {
                            self.audioPlayer?.pause()
                            self.isPlaying = false
                            self.stopHighlighting()
                        }
                        break
                    }
                    wordIndexInText += wordLength + 1  // Increment the index, accounting for spaces between words
                }
            }
        }

    // Stop the word highlighting
        func stopHighlighting() {
            timer?.invalidate()
            currentHighlightedRange = NSRange(location: 0, length: 0)
        }

        /// Controls the playback of the audio from a specific word's position.
        func playAudio(from word: WordData) {
            // Ensure the audio player exists
            guard let audioPlayer = audioPlayer else { return }
            // Toggle between playing and pausing the audio
        
        if isPlaying {
            audioPlayer.pause()
            lastPausedTime = audioPlayer.currentTime // Store the time when paused
            stopHighlighting()
            isPlaying = false
            stopAudioTimer?.invalidate() // Invalidate the timer if it's set
        } else {
            currentWord = word
            if let pausedTime = lastPausedTime, pausedTime != 0.0 {
                audioPlayer.currentTime = pausedTime
            } else {
                audioPlayer.currentTime = word.sec
            }
            audioPlayer.play()
            isPlaying = true
            startHighlighting()
            let duration = endTime(for: word.pageNum) - audioPlayer.currentTime
            stopAudioTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.audioPlayer?.pause()
                self?.stopHighlighting()
                self?.isPlaying = false
            }
        }
    }

    // When the audio finishes playing
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopHighlighting()
        currentWord = nil
        lastPausedTime = 0.0
    }
    
    // Calculate the time the audio should stop for the current page
    func endTime(for currentPage: Int) -> Double {
        // Calculate the time to stop audio based on the last word on the page
        if let lastWordOnPage = words.filter({ $0.pageNum == currentPage }).last {
            if let nextWord = words.first(where: { $0.pageNum == currentPage && $0.wordNum > lastWordOnPage.wordNum }) {
                return nextWord.sec
            }
            return audioPlayer?.duration ?? 0
        }
        return 0
    }

    // Handle tasks required when transitioning between pages
        func handlePageTransition() {
            // If the audio is playing, pause it, stop highlighting, and set the status
            // Also, determine the starting time for the next page
        if isPlaying {
            audioPlayer?.pause()
            stopHighlighting()
            isPlaying = false
        }
        if let firstWordOnNewPage = words.first(where: { $0.pageNum == currentPage }) {
            lastPausedTime = firstWordOnNewPage.sec
        }
    }
}

struct StoryView: View {
    @StateObject var viewModel = ViewModel()
    @State private var timer: Timer?

    var body: some View {
        // The outermost ZStack is used to overlay different views on top of one another.
        // This way, the background image, text, and other elements appear stacked.
        ZStack {
            // Set the background image to be resizable and to fill the entire view.
            Image("background_image")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            // Vertically stack the story title, content, and control buttons.
            VStack(spacing: 20) {
                // Display the story title.
                Text("The Three Little Fairies")
                    .font(.title)
                    .padding(.top, 0)
                    .foregroundColor(Color("textColor"))

                // Create a scrolling text view with highlighted text based on the current word being read.
                ScrollingTextView(attributedString: viewModel.getAttributedText(for: getCurrentPageText()), highlightRange: $viewModel.currentHighlightedRange)
                    .padding(.horizontal)
                    .onReceive(viewModel.$lastHighlightedWordIndex) { _ in
                        // React to changes in the highlighted word index.
                        // Whenever the highlighted word changes, this block is triggered.
                        // This is essential to ensure the ScrollingTextView updates as needed.
                    }

                // Control buttons to navigate between pages or play/pause the audio.
                HStack(spacing: 50) {
                    // If on the first page, show a faded left arrow (indicating no previous page).
                    if viewModel.currentPage == 1 {
                        Image(systemName: "arrow.left")
                            .opacity(0)
                    } else {
                        // Navigate to the previous page.
                        Button(action: {
                            // Ensure multiple quick button presses are not registered.
                            if viewModel.isButtonPressAllowed() {
                                // Safely decrease the current page number.
                                viewModel.currentPage = max(viewModel.currentPage - 1, 1)
                                viewModel.handlePageTransition()
                                
                                // Play the audio for the first word on the new page.
                                if let word = viewModel.words.first(where: { $0.pageNum == viewModel.currentPage }) {
                                    viewModel.playAudio(from: word)
                                }
                            }
                        }) {
                            Image(systemName: "arrow.left")
                        }
                    }
                    
                    // Play/Pause button.
                    Button(action: {
                        // Play the audio for the first word on the current page.
                        if let word = viewModel.words.first(where: { $0.pageNum == viewModel.currentPage }) {
                            viewModel.playAudio(from: word)
                        }
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    }
                    // Detect changes in the audio playing status.
                    .onChange(of: viewModel.isPlaying, perform: { value in
                        if value {
                            // Logic for starting highlighting can be added if needed.
                        } else {
                            // Optionally invalidate the timer if you need to stop some repetitive task.
                            // timer?.invalidate()
                        }
                    })
                    
                    // If not on the last page, show the "next" button.
                    if viewModel.currentPage < viewModel.words.last?.pageNum ?? 1 {
                        Button(action: {
                            if viewModel.isButtonPressAllowed() {
                                // Safely increase the current page number.
                                let maxPageNum = viewModel.words.last?.pageNum ?? 1
                                viewModel.currentPage = min(viewModel.currentPage + 1, maxPageNum)
                                viewModel.handlePageTransition()
                                
                                // Play the audio for the first word on the new page.
                                if let word = viewModel.words.first(where: { $0.pageNum == viewModel.currentPage }) {
                                    viewModel.playAudio(from: word)
                                }
                            }
                        }) {
                            Image(systemName: "arrow.right")
                        }
                    } else {
                        // If on the last page, show a faded right arrow (indicating no next page).
                        Image(systemName: "arrow.right")
                            .opacity(0)
                    }
                }
                .padding(.bottom)

                // Display the current page number and total page count.
                Text("\(viewModel.currentPage) of \(viewModel.words.last?.pageNum ?? 1)")
                    .foregroundColor(Color("textColor"))
            }
            .padding([.leading, .trailing])
        }
    }

    // Return the text content for the current page.
    func getCurrentPageText() -> String {
        // Filter words for the current page and join them into a sentence.
        return viewModel.words.filter { $0.pageNum == viewModel.currentPage }.map { $0.word }.joined(separator: " ")
    }
}


// UIViewRepresentable type to create a SwiftUI view backed by UIKit's UILabel with NSAttributedString.
struct AttributedText: UIViewRepresentable {
    
    // Holds the attributed string that needs to be displayed.
    var attributedString: NSAttributedString
    // Optional font to set for the UILabel. Default is nil.
    var font: UIFont?
    
    // Creates the UILabel that will be shown in the SwiftUI view.
    func makeUIView(context: UIViewRepresentableContext<AttributedText>) -> UILabel {
        // Initialize a new UILabel.
        let label = UILabel()
        // Allows the label to display multiple lines.
        label.numberOfLines = 0
        // Breaks the line at word boundaries.
        label.lineBreakMode = .byWordWrapping
        // Set the preferred width for the label taking into consideration some padding (20 points on each side).
        // This width helps in wrapping the text inside the label.
        label.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 40
        return label
    }
    
    // Updates the UILabel with the provided attributed string.
    func updateUIView(_ uiView: UILabel, context: UIViewRepresentableContext<AttributedText>) {
        // Assign the attributed string to the UILabel's `attributedText` property.
        uiView.attributedText = attributedString
    }
}

// A SwiftUI preview for the main StoryView.
struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        StoryView()
    }
}

// UIViewRepresentable type to create a SwiftUI view backed by UIKit's UITextView with NSAttributedString,
// which also supports scrolling.
struct ScrollingTextView: UIViewRepresentable {
    
    // Holds the attributed string that needs to be displayed.
    var attributedString: NSAttributedString
    // A range that defines the portion of the text that should be highlighted.
    @Binding var highlightRange: NSRange
    
    // Creates the UITextView that will be shown in the SwiftUI view.
    func makeUIView(context: Context) -> UITextView {
        // Initialize a new UITextView.
        let textView = UITextView()
        // Enable scrolling within the text view.
        textView.isScrollEnabled = true
        // Allows the text view to respond to user interactions.
        textView.isUserInteractionEnabled = true
        // Disallows editing of the text inside the text view.
        textView.isEditable = false
        // Sets the background of the text view to be transparent.
        textView.backgroundColor = UIColor.clear
        return textView
    }
    
    // Updates the UITextView with the provided attributed string and scrolls to the highlighted range.
    func updateUIView(_ textView: UITextView, context: Context) {
        // Assign the attributed string to the UITextView's `attributedText` property.
        textView.attributedText = attributedString
        
        // DispatchQueue ensures that the UI updates are dispatched on the main thread.
        DispatchQueue.main.async {
            // Convert NSRange to UITextRange which is required to extract the rect for the highlighted range.
            if let start = textView.position(from: textView.beginningOfDocument, offset: highlightRange.location),
               let end = textView.position(from: start, offset: highlightRange.length),
               let textRange = textView.textRange(from: start, to: end) {
                
                // Get the rectangle for the highlighted range.
                let rect = textView.firstRect(for: textRange)
                // Scroll the text view so the highlighted range is visible.
                textView.scrollRectToVisible(rect, animated: true)
            }
        }
    }
}
