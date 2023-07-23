//
//  PopularStoryViews.swift
//  WonderSproutsApp_v4
//
//  Created by Charles Atchison on 7/23/23.
//

import SwiftUI

struct PopularStoriesView: View {
    
    var body: some View {
        ZStack {
            
            Image("background_image")
                .resizable()
                .ignoresSafeArea()

            VStack {
                Text("Popular Stories") // Your title here
                    .font(.largeTitle)
                    .foregroundColor(Color("textColor"))
                    .padding(.top, 50) // Adjust this padding to position your title appropriately

                ScrollView(.vertical) {
                    LazyVStack {
                        ForEach(0..<Int.max, id: \.self) { section in // Infinite sections for vertical scroll
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    Spacer()
                                    LazyHStack {
                                        ForEach(0..<2, id: \.self) { row in // 2 items for horizontal scroll
                                            storyButton(for: section * 2 + row + 1)
                                        }
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
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
                VStack {
                    Text("Popular Story Num: \(storyNumber)")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    Image("ws_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                    
                    Text("This is a brief description of the popular story number \(storyNumber).")
                        .font(.footnote)
                        .padding(.top, 5)
                        .frame(width: 150)
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
