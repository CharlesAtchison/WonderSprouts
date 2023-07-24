//
//  StoryView.swift
//  WonderSproutsApp_v4
//
//  Created by Charles Atchison on 7/21/23.
//

import SwiftUI
import AVFoundation

extension AnyTransition {
    static var scaleAndSlide: AnyTransition {
        let insertion = AnyTransition.move(edge: .trailing)
            .combined(with: .scale(scale: 0, anchor: .leading))
        let removal = AnyTransition.move(edge: .leading)
            .combined(with: .scale(scale: 0, anchor: .trailing))
        return .asymmetric(insertion: insertion, removal: removal)
    }
}

class Debouncer {
    var callback: (() -> Void)?
    private var debounceTime: TimeInterval
    private var lastFireTime: DispatchTime = .now()

    init(debounceTime: TimeInterval) {
        self.debounceTime = debounceTime
    }

    func call() {
        let now = DispatchTime.now()
        let dispatchDelay = now + debounceTime
        DispatchQueue.main.asyncAfter(deadline: dispatchDelay) {
            let whenToFire = DispatchTime.now() + self.debounceTime
            if whenToFire >= self.lastFireTime + self.debounceTime {
                self.callback?()
            }
        }
        lastFireTime = now
    }
}

struct StoryView: View {
    @State private var currentPage: Int = 0
    @State private var attributedContent: NSAttributedString = NSAttributedString()
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var speaker = Speak()
    
    
    private var backDebouncer = Debouncer(debounceTime: 0.3)
    private var nextDebouncer = Debouncer(debounceTime: 0.3)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("background_image")
                    .resizable()
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    
                    PageContentView(text: defaultStoryPages[currentPage], speaker: speaker, currentPage: $currentPage)
                        .id(currentPage)
                        .transition(.scaleAndSlide)
                    
                    HStack(spacing: 60) {
                        // Back Button
                        if currentPage > 0 {
                            Image(systemName: "arrow.left.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(Color("buttonColor"))
                                .background(Color("selectedButtonColor"))
                                .clipShape(Circle())
                                .onTapGesture {
                                    backDebouncer.callback = {
                                        withAnimation {
                                            if self.currentPage > 0 {
                                                // First, we stop any ongoing speech.
                                                self.speaker.stopSpeaking()
                                                // Then we navigate to the previous page.
                                                self.currentPage -= 1
                                                // If the speaker was actively speaking (not paused), speak the new content.
                                                if !self.speaker.isPaused {
                                                    self.speaker.toggleSpeech(text: defaultStoryPages[self.currentPage], pageNumber: self.currentPage)
                                                }
                                            }
                                        }
                                    }
                                    backDebouncer.call()
                                }
                        } else {
                            Image(systemName: "arrow.left.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .opacity(0)
                        }
                        
                        // Play/Pause Button
                        Button(action: {
                            speaker.toggleSpeech(text: defaultStoryPages[currentPage], pageNumber: currentPage)
                        }) {
                            // Depending on whether the speaker is actively speaking, show the appropriate image.
                            Image(systemName: speaker.isSpeaking ? "pause.circle.fill" : "play.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(Color("buttonColor"))
                                .background(Color("selectedButtonColor"))
                                .cornerRadius(20) // Add corner radius for the button
                        }
                        
                        // Next Button
                        if currentPage < defaultStoryPages.count - 1 {
                            Image(systemName: "arrow.right.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(Color("buttonColor"))
                                .background(Color("selectedButtonColor"))
                                .clipShape(Circle())
                                .onTapGesture {
                                    nextDebouncer.callback = {
                                        withAnimation {
                                            if self.currentPage < defaultStoryPages.count - 1 {
                                                // First, we stop any ongoing speech.
                                                self.speaker.stopSpeaking()
                                                // Then we navigate to the next page.
                                                self.currentPage += 1
                                                // If the speaker was actively speaking (not paused), speak the new content.
                                                if !self.speaker.isPaused {
                                                    self.speaker.toggleSpeech(text: defaultStoryPages[self.currentPage], pageNumber: self.currentPage)
                                                }
                                            }
                                        }
                                    }
                                    nextDebouncer.call()
                                }
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .opacity(0)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    Slider(value: $speaker.rate, in: 0.1...1.0, step: 0.1) {
                        Text("Rate")
                    }
                    .padding()
                    .accentColor(Color("textColor"))
                }
                .onChange(of: speaker.currentHighlightedRange, perform: { range in
                    attributedContent = speaker.getAttributedText(for: defaultStoryPages[currentPage])
                })
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(leading: customBackButton(speaker: speaker, presentationMode: presentationMode))
            }
        }
    }
}
    
func customBackButton(speaker: Speak, presentationMode: Binding<PresentationMode>) -> some View {
    Button(action: {
        // Stop the audio when the back button is pressed
        speaker.stopSpeaking()
        // Navigate back to the previous view
        presentationMode.wrappedValue.dismiss()
    }) {
        HStack {
            Image(systemName: "arrow.left") // Choose your desired image
            Text("Back")
        }
    }
}



struct PageContentView: View {
    let text: String
    @ObservedObject var speaker: Speak
    @Binding var currentPage: Int // <-- We make it a Binding to change its value outside

    var body: some View {
        AttributedText(attributedString: speaker.getAttributedText(for: text))
            .padding()
            .gesture(DragGesture(minimumDistance: 50, coordinateSpace: .local) // Recognize drags more than 50 points
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height

                    if abs(horizontalAmount) > abs(verticalAmount) { // Ensure it's mostly a horizontal drag
                        if horizontalAmount < 0 && currentPage < defaultStoryPages.count - 1 { // left swipe
                            withAnimation {
                                speaker.stopSpeaking()
                                currentPage += 1
//                                if !speaker.isPaused {
//                                    speaker.speak(text: defaultStoryPages[currentPage])
//                                }
                            }
                        } else if horizontalAmount > 0 && currentPage > 0 { // right swipe
                            withAnimation {
                                speaker.stopSpeaking()
                                currentPage -= 1
//                                if !speaker.isPaused {
//                                    speaker.speak(text: defaultStoryPages[currentPage])
//                                }
                            }
                        }
                    }
                }
            )
    }
}


struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        StoryView()
    }
}

let defaultStoryPages: [String] = [
    // Page 1
        "Once upon a time, in a vast African savannah, there was a young giraffe named Gigi. With her long, slender neck, Gigi could reach the tippy-top branches of the tallest acacia trees. But more than munching on leaves, Gigi loved gazing up at the sky, especially the moon. She often wondered what it might feel like to dance among the stars and touch the radiant moon.",
        
        // Page 2
        "Every night, Gigi would lie down on a hill, her large, dreamy eyes reflecting the silver moonlight. The other animals thought she was daydreaming, but Gigi had a secret wish – to visit the moon. 'How wonderful it would be to leap over the craters and play hide-and-seek behind the moon rocks!' she thought.",
]


// Function to split a story into pages (Not required for the defaultStoryPages as it's already split, but useful for other stories)
func splitStoryIntoPages(story: String, wordsPerPage: Int) -> [String] {
    let words = story.split(separator: " ")
    var pages: [String] = []
    var currentPageWords: [String.SubSequence] = []

    for word in words {
        currentPageWords.append(word)
        if currentPageWords.count == wordsPerPage {
            pages.append(currentPageWords.joined(separator: " "))
            currentPageWords = []
        }
    }

    if !currentPageWords.isEmpty {
        pages.append(currentPageWords.joined(separator: " "))
    }

    return pages
}


class Speak: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isSpeaking: Bool = false
    @Published var currentHighlightedRange: NSRange = NSRange(location: 0, length: 0)
    private var lastText: String = ""
    private var audioPlayer: AVAudioPlayer?
    private var highlightTimings: [(NSRange, Double)] = [] // (Range to highlight, start time for highlight)
    private var timer: Timer?
    @Published var rate: Double = 0.5
    @Published var isPaused: Bool = false

    override init() {
        super.init()
    }

    func toggleSpeech(text: String, pageNumber: Int) {
        if let player = audioPlayer, player.isPlaying {
            player.pause()
            isSpeaking = false
            isPaused = true
        } else {
            if isPaused {
                audioPlayer?.play()
                isPaused = false
            } else {
                setupAudio(for: pageNumber)
                playAudio(text: text)
            }
        }
    }

    private func setupAudio(for page: Int) {
        // Adjust the page value.
        let adjustedPage = page + 1
        
        guard let path = Bundle.main.path(forResource: "story_audio_\(adjustedPage)", ofType: "wav") else {
            print("Audio file not found for adjusted page \(adjustedPage)")
            return
        }
        let url = URL(fileURLWithPath: path)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
        } catch {
            print("Error initializing audio player: \(error.localizedDescription)")
        }
    }

    func playAudio(text: String) {
        lastText = text
        audioPlayer?.play()
        isSpeaking = true
        setupHighlightTimings(text: text) // This method will set the highlightTimings array based on the text
        startHighlightingTimer()
    }

    func stopSpeaking() {
        audioPlayer?.stop()
        isSpeaking = false
        isPaused = false
        timer?.invalidate()
        timer = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isSpeaking = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        currentHighlightedRange = NSRange(location: 0, length: 0)
    }

    private func setupHighlightTimings(text: String) {
        // Set highlightTimings based on the text.
        // This is a mock. You need to refine and set exact timings based on the audio narration.
        // Example: highlightTimings = [(NSRange(location: 0, length: 5), 0.0), ...]
    }

    private func startHighlightingTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let currentTime = self.audioPlayer?.currentTime else { return }
            for (range, time) in self.highlightTimings {
                if currentTime >= time {
                    self.currentHighlightedRange = range
                    break
                }
            }
        }
    }
    func getAttributedText(for text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 30)])
        attributedString.addAttribute(.foregroundColor, value: UIColor(named: "textColor")!, range: NSRange(location: 0, length: text.count))
        attributedString.addAttribute(.backgroundColor, value: UIColor.yellow, range: currentHighlightedRange)
        return attributedString
    }
}


struct AttributedText: UIViewRepresentable {
    var attributedString: NSAttributedString

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.isEditable = false
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.widthTracksTextView = true
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedString
    }
}
