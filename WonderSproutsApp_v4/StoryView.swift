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
                                                    self.speaker.speak(text: defaultStoryPages[self.currentPage])
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
                            speaker.toggleSpeech(text: defaultStoryPages[currentPage])
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
                                                    self.speaker.speak(text: defaultStoryPages[self.currentPage])
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
                                if !speaker.isPaused {
                                    speaker.speak(text: defaultStoryPages[currentPage])
                                }
                            }
                        } else if horizontalAmount > 0 && currentPage > 0 { // right swipe
                            withAnimation {
                                speaker.stopSpeaking()
                                currentPage -= 1
                                if !speaker.isPaused {
                                    speaker.speak(text: defaultStoryPages[currentPage])
                                }
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
    
    // Page 3
    "One day, a wise old owl named Oliver overheard Gigi’s moonlit musings. Oliver had traveled far and wide and heard tales of magical rockets that could take anyone to the moon. 'Why not build a rocket?' he suggested to Gigi with a twinkle in his eye.",
    
    // Page 4
    "Thrilled by the idea, Gigi teamed up with her friends: Timmy the Tortoise, who was a brilliant engineer, and Penny the Parrot, a crafty gatherer. Together, they collected materials and began building their very own moon-bound rocket.",
    
    // Page 5
    "After many days and nights of hard work, the rocket was ready. Painted in vibrant colors and adorned with twinkling stars, it stood tall, waiting for its maiden voyage. Gigi, with her friends by her side, climbed aboard, eager for the journey ahead.",
    
    // Page 6
    "The rocket soared into the night, leaving a trail of sparkles. As they ascended higher, the vast savannah became a distant patchwork quilt. Soon, the blue sky turned to inky black, and the stars shone brighter than ever.",
    
    // Page 7
    "After what seemed like hours, they finally landed with a soft thud. Gigi stepped out and was amazed by the vast lunar landscape. The ground was dusty and dotted with craters. The Earth looked like a blue marble in the distant sky.",
    
    // Page 8
    "While exploring, Gigi stumbled upon a peculiar sight: a shimmering alien with three eyes and a shiny, green body. The alien introduced himself as Alaric. He had been living on the moon for centuries, observing Earth and its wonders.",
    
    // Page 9
    "Alaric showed Gigi around, introducing her to the wonders of the moon. They leapt over giant craters, played with moon rocks, and even had a picnic with lunar ice cream, which tasted like nothing Gigi had ever eaten before.",
    
    // Page 10
    "As they spent more time together, Gigi and Alaric shared stories of their homes. Gigi spoke of the vast savannah, the animals, and the warm sun. Alaric told tales of galaxies beyond, of cosmic dances, and stars that sang.",
    
    // Page 11
    "One day, Alaric took Gigi to a special place: a hidden valley where stars would come down to rest. The valley was filled with lights, music, and colors that danced around. It was the most magical sight Gigi had ever seen.",
    
    // Page 12
    "Gigi's stay on the moon was filled with magical moments, but she soon began to miss her home. She missed the golden sunrise, the rustling leaves, and the familiar sounds of the savannah. Sensing her homesickness, Alaric had an idea.",
    
    // Page 13
    "He gave Gigi a small, glowing moonstone. 'Whenever you miss the moon, hold this stone, and it'll show you its magic,' Alaric said with a smile. It was a gift of friendship, a token to remember their time together.",
    
    // Page 14
    "The day came for Gigi to return home. With a heavy heart, she said her goodbyes to Alaric and the moon. The rocket's engines roared to life, and they began their descent back to Earth.",
    
    // Page 15
    "When they landed back on the savannah, a crowd of animals greeted them with cheers and excitement. Everyone was eager to hear about Gigi’s adventures. She narrated tales of the moon's magic, the alien friend she made, and the wonders she'd seen.",
    
    // Page 16
    "Days turned into weeks, and weeks into months. Life returned to normal for Gigi, but she often found herself gazing up at the moon, reminiscing about her adventure. The moonstone Alaric gave her always hung around her neck, glowing softly.",
    
    // Page 17
    "One evening, as Gigi lay on her favorite hill, she held the moonstone close to her heart. To her surprise, it began to glow brightly, and she could hear Alaric's voice, singing a lullaby from the moon.",
    
    // Page 18
    "The gentle song reminded Gigi that no matter the distance, true friendships never fade. Every time she missed Alaric, she'd listen to the moonstone's song, and it felt like he was right beside her.",
    
    // Page 19
    "Gigi’s adventure became a legendary tale in the savannah. Animals from far and wide would come to hear about her journey to the moon and her alien friend. And every time she narrated her story, the moonstone would glow a little brighter.",
    
    // Page 20
    "And so, in the heart of the savannah, under the silver glow of the moon, Gigi’s tale became a beacon of hope, wonder, and the magic that awaits when one dares to dream. And every dreamer on Earth knew that adventures were waiting, just a dream away."
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


class Speak: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var rate: Float = 0.5
    @Published var isSpeaking: Bool = false
    @Published var currentHighlightedRange: NSRange = NSRange(location: 0, length: 0)
    private var lastText: String = ""
    var isPaused: Bool = false
    
    private var voiceSynth = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        voiceSynth.delegate = self
    }


    func toggleSpeech(text: String) {
        if voiceSynth.isSpeaking {
            if voiceSynth.isPaused {
                voiceSynth.continueSpeaking()
                isPaused = false
                isSpeaking = true
            } else {
                voiceSynth.pauseSpeaking(at: .word)
                isPaused = true
                isSpeaking = false
            }
        } else {
            speak(text: text)
        }
    }

    func speak(text: String) {
        lastText = text
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        voiceSynth.speak(utterance)
        isSpeaking = true
        isPaused = false
    }

    func stopSpeaking() {
        voiceSynth.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
    }

    // Delegate method called when the synthesizer starts speaking
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
        isPaused = false
    }

    // Delegate method called when the synthesizer pauses speaking
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
            currentHighlightedRange = characterRange
        }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        currentHighlightedRange = NSRange(location: 0, length: 0)
    }
    
    func getAttributedText(for text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        
        // Getting the asset-defined color for UIKit
        let textColor = UIColor(named: "textColor") ?? UIColor.black

        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: UIFont.systemFont(ofSize: 30)
        ]
        let highlightAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.yellow,
            .font: UIFont.systemFont(ofSize: 35)
        ]
        
        attributedString.addAttributes(defaultAttributes, range: NSRange(location: 0, length: text.count))
        
        if isSpeaking {
            attributedString.addAttributes(highlightAttributes, range: currentHighlightedRange)
        }
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
