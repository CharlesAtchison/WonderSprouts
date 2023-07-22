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
    @ObservedObject var speaker = Speak()

    private var backDebouncer = Debouncer(debounceTime: 0.3)
    private var nextDebouncer = Debouncer(debounceTime: 0.3)

    var body: some View {
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
    """
    *Once upon a time*, in the mystical land of Camelot, there was a legendary king named *Arthur*. He was known far and wide for his wisdom, valor, and his famous sword *Excalibur*, which he pulled from a stone, proving his right to rule. The kingdom prospered under King Arthur's rule, and he was loved by his subjects. However, not everything was peaceful in Camelot. There were rumors of a traitor among the knights of the Round Table, which troubled Arthur greatly. One day, a mysterious sorceress named *Morgana* appeared at the court, claiming to be an ally. Arthur was skeptical, but he couldn't deny the powerful magic she possessed. As time went on, Morgana's intentions became unclear, and the kingdom's peace hung in the balance.
    """,

    // Page 2
    """
    In the second chapter of the tale, darkness loomed over Camelot. King Arthur and his loyal knights embarked on a quest to find the legendary *Holy Grail*, a mystical artifact said to grant eternal life and restore harmony to the kingdom. The journey was perilous, filled with treacherous landscapes and dangerous foes. Along the way, Arthur faced many challenges that tested his courage and leadership. Despite the odds, he and his knights persevered, fueled by the hope of a brighter future. As they neared the Holy Grail, Morgana's true intentions were revealed. She sought the Grail's power for herself, intending to use it to conquer Camelot and plunge the land into darkness. Arthur knew he had to stop her at all costs.
    """,

    // Page 3
    """
    A climactic battle ensued between Arthur and Morgana, with magic clashing against steel. In the end, Arthur's bravery and righteousness proved stronger, and he defeated Morgana, banishing her from the kingdom forever. With the threat of Morgana gone, King Arthur and his knights finally reached the Holy Grail's resting place. It glowed with a divine light, confirming their quest's righteousness. The artifact was used to heal the land, bringing prosperity and unity back to Camelot. The tale of King Arthur's quest and triumph spread throughout the land, becoming a symbol of hope and justice. To this day, his legend lives on, inspiring generations with his bravery, leadership, and the belief that good will always prevail over evil.
    """,

    // Page 4
    """
    But peace never lasts forever. As time passed, a new threat emerged, casting its dark shadow upon Camelot. A powerful warlord named Mordred, believed to be Arthur's own son, rose to challenge his father's rule. Mordred was fueled by jealousy and greed, seeking to claim the throne for himself. Arthur faced the heart-wrenching reality of having to confront his own flesh and blood. He knew that the fate of Camelot depended on him putting an end to Mordred's treachery. The final confrontation between father and son was a clash of emotions as much as it was a battle of swords. Mordred was cunning and ruthless, but Arthur's love for his kingdom and people gave him the strength to stand firm.
    """,

    // Page 5
    """
    In the end, Arthur emerged victorious, but at a terrible cost. The wounds of the battle ran deep, and the land mourned the loss of both a king and a prince. As Arthur lay dying, he entrusted his loyal knight, Sir Bedivere, with the task of returning Excalibur to the Lady of the Lake. With a heavy heart, Sir Bedivere fulfilled the king's wish and cast the sword back into the waters. As the sword disappeared beneath the surface, a hand reached up from the lake to catch it. The Lady of the Lake had received Excalibur once again, signifying the end of Arthur's reign and the passing of an era.
    """,

    // Page 6
    """
    But legends never truly die. Some say that Arthur's body was taken to the mystical isle of Avalon, where he rests, ready to awaken in Britain's hour of need. And so, the tale of King Arthur lives on, immortalized in songs and stories, inspiring countless generations to come. Camelot's legacy endures, a beacon of hope in dark times, a reminder of the extraordinary potential that lies within each of us. And while the knights of the Round Table have scattered, their code of chivalry and honor lives on in the hearts of those who dare to dream and strive for a better world.
    """,

    // Page 7
    """
    The end... or perhaps just the beginning of a new chapter in the story of Camelot. For as long as there are those who believe in the ideals of King Arthur, the legend will continue to shape the destiny of the realm. And so, the tale of King Arthur lives on, weaving its magic through the tapestry of time, forever and always. Thus concludes the epic tale of King Arthur, a saga that will be retold and cherished by generations to come.
    """,

    // Page 8
    """
    And so, the legacy of King Arthur and Camelot lives on, an eternal flame of hope that burns brightly in the hearts of those who hear the story. Let it serve as a reminder that within each of us lies the potential for greatness, and that the values of courage, loyalty, and justice will always prevail. As the story of King Arthur and Camelot comes to an end, the echoes of their adventures will resound throughout the annals of history.
    """,

    // Page 9
    """
    And thus, the tale of King Arthur lives on, inspiring hearts and minds across the ages, a testament to the enduring power of legends. Though the pages of this story may close, the legend of King Arthur and his knights will forever remain alive in the hearts of those who believe.
    """,

    // Page 10
    """
    For as long as there are storytellers and dreamers, the legacy of King Arthur and Camelot will continue to shine bright. And so, the epic tale of King Arthur and Camelot comes to an end, but its magic will forever linger in the hearts of all who hear it.
    """,

    // Page 11
    """
    And so, the legend of King Arthur and Camelot will live on, inspiring the hearts of those who seek truth, justice, and nobility. As the story of King Arthur and Camelot reaches its conclusion, may it remind us all that legends never truly die.
    """,

    // Page 12
    """
    The tale of King Arthur and Camelot may end, but the spirit of chivalry and honor will endure in the hearts of all who cherish it. And so, the story of King Arthur and Camelot draws to a close, leaving behind a legacy that will inspire generations to come.
    """,

    // Page 13
    """
    But fear not, for the spirit of King Arthur and the ideals of Camelot will forever live on, guiding us through the pages of our own stories, lighting the way to a better world.
    """
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



