//
//  PopularStoryViews.swift
//  WonderSproutsApp_v4
//
//  Created by Charles Atchison on 7/23/23.
//

import SwiftUI

struct PopularStoriesView: View {
    
    // Adaptive Grid Layout
    let columns: [GridItem] = Array(repeating: .init(.adaptive(minimum: 170, maximum: 200)), count: 2)  // maximum can be adjusted based on your design preference

    var body: some View {
        ZStack {
            
            Image("background_image")
                .resizable()
                .ignoresSafeArea()

            VStack {
                Text("Popular Stories")
                    .font(.largeTitle)
                    .foregroundColor(Color("textColor"))
                    .padding(.top, 50)

                ScrollView(.vertical) {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(0..<100, id: \.self) { story in  // Replace 10 with your story count or array count
                            storyButton(for: story + 1)
                        }
                    }
                    .padding()
                }
            }
        }
        .ignoresSafeArea(.all)
    }
    
    func storyButton(for storyNumber: Int) -> some View {
        Button(action: {
            // Placeholder for button action
        }) {
            NavigationLink(destination: StoryView()) {
                let frameWidth = CGFloat(170)
                VStack {
                    Text("Popular Story \(storyNumber)")
                        .font(.headline)
                        .padding(.bottom, 5)
                        .frame(width: frameWidth)
                    
                    Image("ws_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: frameWidth)
                    
                    Text("This is a brief description of the popular story number \(storyNumber).")
                        .font(.footnote)
                        .padding(.top, 5)
                        .frame(width: frameWidth)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .buttonStyle(BigButtonStyle())
    }
}

struct PopularStoryViews_Previews: PreviewProvider {
    static var previews: some View {
        PopularStoriesView()
    }
}
