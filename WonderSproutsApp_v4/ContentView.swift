//
//  ContentView.swift
//  WonderSproutsApp_v4
//
//  Created by Charles Atchison on 7/20/23.
//

import SwiftUI

struct ContentView: View {
    
    // Add any @State properties here if needed for dynamic UI behavior or storing user input
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("background_image")
                    .resizable()
                    .ignoresSafeArea()

                VStack {
                // Using HStack to horizontally arrange the Main Title and the Menu Bar.
                        HStack {
                            // Main Title at the very top.
                            Text("Welcome to WonderSprouts")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color("textColor"))
                                .padding(.leading)
                                .padding(.top, 20)
                                .layoutPriority(1) // Ensuring the title occupies available space before the menu icon.
                            
                            Spacer() // Pushes items apart, maximizing the space in between.
                            
                            // Menu Bar on the upper right.
                            Menu {
                                // ForEach loop dynamically creates menu options.
                                ForEach(MenuOption.allOptions, id: \.name) { option in
                                    NavigationLink(destination: option.destination) {
                                        Label(option.name, systemImage: option.imageName)
                                    }
                                }
                            } label: {
                                Image(systemName: "line.horizontal.3")
                                    .font(.title)
                                    .foregroundColor(Color("textColor"))
                                    .padding(.trailing)
                                    .padding(.top, 20)
                            }
                        }

                    // Popular Stories section with horizontal scroll
                    ScrollView(.horizontal) {
                        HStack {
                            // Creating 50 story buttons dynamically
                            ForEach(1...50, id: \.self) { item in
                                Button(action: {
                                    // Placeholder for button action
                                }) {
                                    VStack {
                                        // Title for each story
                                        Text("Popular Story Num: \(item)")
                                            .font(.headline) // Applying a headline font style
                                            .padding(.bottom, 5) // Space below the title

                                        // Story image
                                        Image("ws_logo")
                                            .resizable() // Makes the image resizable
                                            .scaledToFit() // Scales the image to fit within its frame
                                            .frame(width: 150)  // Sets a fixed width for the image

                                        // Story description
                                        Text("This is a brief description of the popular story number \(item).")
                                            .font(.footnote) // Applying a footnote font style
                                            .padding(.top, 5) // Space above the description
                                            .frame(width: 150) // Fixes the width to enable text wrapping
                                    }
                                    // Ensures the VStack doesn't expand more than its content
                                    .fixedSize(horizontal: false, vertical: true)
                                }
                                .buttonStyle(BigButtonStyle()) // Custom button style
                            }
                        }
                    }
                    .padding(.top, 10) // Top padding for the ScrollView to separate it from the top bar

                    Spacer() // Adjust for centering the buttons

                    // Main Menu Buttons
                    VStack(spacing: 16) {
                        ForEach(MainMenuButton.allButtons, id: \.title) { button in
                            NavigationLink(destination: button.destination) {
                                Text(button.title)
                                    .padding() // You can adjust this padding for the buttons
                            }
                            .navigationBarBackButtonHidden(true)
                        }
                        .buttonStyle(BigButtonStyle())
                    }

                    Spacer() // Adjust for centering the buttons
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// Preview for the ContentView in Xcode's canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class MenuOption {
    static let settings = MenuOption(name: "Settings", imageName: "gearshape", color: Color("buttonColor"), destination: AnyView(SettingsView()))
    static let profile = MenuOption(name: "Profile", imageName: "person", color: Color("buttonColor"), destination: AnyView(ProfileView()))
    
    let name: String
    let imageName: String
    let color: Color
    let destination: AnyView
    
    init(name: String, imageName: String, color: Color, destination: AnyView) {
        self.name = name
        self.imageName = imageName
        self.color = color
        self.destination = destination
    }
    
    // Access all predefined options
    static var allOptions: [MenuOption] {
        return [settings, profile]
    }
}


class MainMenuButton {
    static let startYourJourney = MainMenuButton(title: "Start your Journey Here", imageName: "gearshape", destination: AnyView(StoryBuilderView()))
    static let mostPopular = MainMenuButton(title: "Most Popular", imageName: "person", destination: AnyView(StoryBuilderView()))
    static let searchForMore = MainMenuButton(title: "Search for More!", imageName: "person", destination: AnyView(StoryBuilderView()))
    
    let title: String
    let imageName: String
    let destination: AnyView
    let color = Color("buttonColor")
    
    init(title: String, imageName: String, destination: AnyView) {
        self.title = title
        self.imageName = imageName
        self.destination = destination
    }
    
    // Access all predefined buttons
    static var allButtons: [MainMenuButton] {
        return [startYourJourney, mostPopular, searchForMore]
    }
}
