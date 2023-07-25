//
//  StoryView.swift
//  WonderSproutsApp_v4
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
    
    @Published var currentWord: WordData?
    @Published var words: [WordData] = []
    var stopAudioTimer: Timer?
    @Published var lastHighlightedWordIndex: Int? = nil
    let baseFontSize: CGFloat = 30
    var lastPausedTime: Double?

    var currentPage = 1 {
        didSet {
            handlePageTransition()
            currentWord = nil
        }
    }

    var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false
    @Published var highlightedWordNum = 0
    var highlightTimings: [(NSRange, Double)] = []
    @Published var currentHighlightedRange: NSRange = NSRange(location: 0, length: 0)
    
    var timer: Timer?
    
    var lastButtonPressTime = Date().addingTimeInterval(-1) // Initialize with a past time

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
        loadJSON()
        setupAudio()
    }
    
    func loadJSON() {
        if let url = Bundle.main.url(forResource: "combined_story_female", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                words = try JSONDecoder().decode([WordData].self, from: data)
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
    }
    
    func setupAudio() {
        if let audioURL = Bundle.main.url(forResource: "combined_story_female", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                audioPlayer?.delegate = self
            } catch {
                print("Error setting up audio: \(error)")
            }
        }
    }

    func getAttributedText(for text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let baseFontSize: CGFloat = 30
        let baseFont = UIFont.systemFont(ofSize: baseFontSize)
        let highlightedFont = UIFont.systemFont(ofSize: baseFontSize + 5) // Highlighted word will be 5 points larger

        // Set the base font for the entire text
        attributedString.addAttribute(.font, value: baseFont, range: NSRange(location: 0, length: text.count))
        
        // Set the text color
        attributedString.addAttribute(.foregroundColor, value: UIColor(named: "textColor")!, range: NSRange(location: 0, length: text.count))
        
        // Change text color to yellow for the highlighted word
        attributedString.addAttribute(.foregroundColor, value: UIColor.yellow, range: currentHighlightedRange)
        
        // Set the highlighted font size
        attributedString.addAttribute(.font, value: highlightedFont, range: currentHighlightedRange)

        return attributedString
    }

    
    func startHighlighting() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let audioPlayer = self.audioPlayer else { return }
            
            let wordsForCurrentPage = self.words.filter { $0.pageNum == self.currentPage }
            var wordIndexInText = 0
                
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
                    if index == wordsForCurrentPage.count - 1 && audioPlayer.currentTime >= wordData.sec + 0.8 { // Adjust the 0.8 if needed
                        self.audioPlayer?.pause()
                        self.isPlaying = false
                        self.stopHighlighting()
                    }
                    break
                }
                    
                wordIndexInText += wordLength + 1 // +1 for space
            }
        }
    }

    func stopHighlighting() {
        timer?.invalidate()
        currentHighlightedRange = NSRange(location: 0, length: 0)
    }

    func playAudio(from word: WordData) {
        guard let audioPlayer = audioPlayer else { return }
        
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


    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopHighlighting()
        currentWord = nil
        lastPausedTime = 0.0
    }
    
    func endTime(for currentPage: Int) -> Double {
        if let lastWordOnPage = words.filter({ $0.pageNum == currentPage }).last {
            if let nextWord = words.first(where: { $0.pageNum == currentPage && $0.wordNum > lastWordOnPage.wordNum }) {
                return nextWord.sec
            }
            return audioPlayer?.duration ?? 0
        }
        return 0
    }

    func handlePageTransition() {
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
        ZStack {
            Image("background_image")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Gigi the Giraffe")
                    .font(.title)
                    .padding(.top, 0)
                    .foregroundColor(Color("textColor"))

                ScrollingTextView(attributedString: viewModel.getAttributedText(for: getCurrentPageText()), highlightRange: $viewModel.currentHighlightedRange)
                    .padding(.horizontal)
                    .onReceive(viewModel.$lastHighlightedWordIndex) { _ in
                        // This will trigger the updateUIView method in ScrollingTextView whenever the highlighted word changes.
                    }

                HStack(spacing: 50) {
                    if viewModel.currentPage == 1 {
                        Image(systemName: "arrow.left")
                            .opacity(0)
                    } else {
                        Button(action: {
                            if viewModel.isButtonPressAllowed() {
                                viewModel.currentPage = max(viewModel.currentPage - 1, 1)
                                viewModel.handlePageTransition()
                                if let word = viewModel.words.first(where: { $0.pageNum == viewModel.currentPage }) {
                                    viewModel.playAudio(from: word)
                                }
                            }
                        }) {
                            Image(systemName: "arrow.left")
                        }
                    }
                    
                    Button(action: {
                        if let word = viewModel.words.first(where: { $0.pageNum == viewModel.currentPage }) {
                            viewModel.playAudio(from: word)
                        }
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    }
                    .onChange(of: viewModel.isPlaying, perform: { value in
                        if value {
                            // startHighlighting() // Add your logic for this function if required
                        } else {
                            // timer?.invalidate() // If you need to invalidate the timer on change
                        }
                    })
                    
                    if viewModel.currentPage < viewModel.words.last?.pageNum ?? 1 {
                        // For the next button
                        Button(action: {
                            if viewModel.isButtonPressAllowed() {
                                let maxPageNum = viewModel.words.last?.pageNum ?? 1
                                viewModel.currentPage = min(viewModel.currentPage + 1, maxPageNum)
                                viewModel.handlePageTransition()
                                if let word = viewModel.words.first(where: { $0.pageNum == viewModel.currentPage }) {
                                    viewModel.playAudio(from: word)
                                }
                            }
                        }) {
                            Image(systemName: "arrow.right")
                        }

                    } else {
                        Image(systemName: "arrow.right")
                            .opacity(0)
                    }
                }
                .padding(.bottom)

                // Page identifier
                Text("\(viewModel.currentPage) of \(viewModel.words.last?.pageNum ?? 1)")
                    .foregroundColor(Color("textColor"))

            }
            .padding([.leading, .trailing])
        }
    }
    
    func getCurrentPageText() -> String {
        return viewModel.words.filter { $0.pageNum == viewModel.currentPage }.map { $0.word }.joined(separator: " ")
    }
}

struct AttributedText: UIViewRepresentable {
    var attributedString: NSAttributedString
    var font: UIFont?
    
    func makeUIView(context: UIViewRepresentableContext<AttributedText>) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 40 // Assumes 20pt padding on each side
        return label
    }
    
    func updateUIView(_ uiView: UILabel, context: UIViewRepresentableContext<AttributedText>) {
        uiView.attributedText = attributedString
    }
}

struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        StoryView()
    }
}

struct ScrollingTextView: UIViewRepresentable {
    var attributedString: NSAttributedString
    @Binding var highlightRange: NSRange
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.isUserInteractionEnabled = true // adjust as per your requirements
        textView.isEditable = false
        textView.backgroundColor = UIColor.clear
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        textView.attributedText = attributedString
        
        DispatchQueue.main.async {
            if let start = textView.position(from: textView.beginningOfDocument, offset: highlightRange.location),
               let end = textView.position(from: start, offset: highlightRange.length),
               let textRange = textView.textRange(from: start, to: end) {
                
                let rect = textView.firstRect(for: textRange)
                textView.scrollRectToVisible(rect, animated: true)
            }
        }
    }
}
