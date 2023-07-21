//
//  AppTheme.swift
//  WonderSproutsApp_v4
//
//  Created by Charles Atchison on 7/20/23.
//

import Foundation

import SwiftUI

class AppTheme: ObservableObject {
    
    let whoButtonValues: [String] = [
        "Alice the Adventurer", "Buzz the Bee", "Charlie the Chimp", "Daisy the Dinosaur", "Ella the Explorer",
        "Frank the Firefighter", "Grace the Gardener", "Henry the Hunter", "Ivy the Inventor", "Jack the Juggler",
        "Katie the Knight", "Leo the Lumberjack", "Mia the Magician", "Noah the Navigator", "Olivia the Olympian",
        "Peter the Pilot", "Quinn the Quizmaster", "Ruby the Rockstar", "Sam the Scientist", "Tessa the Teacher",
        "Uma the Urban Farmer", "Victor the Veterinarian", "Willow the Writer", "Xavier the Xylophonist", "Yara the Yoga Instructor",
        "Zoe the Zookeeper", "Aaron the Archer", "Bella the Baker", "Caleb the Cowboy", "Diana the Dancer",
        "Ethan the Engineer", "Fiona the Farmer", "Gavin the Gamer", "Hannah the Historian", "Isaac the Illustrator",
        "Jasmine the Jester", "Kevin the King", "Lily the Librarian", "Max the Magician", "Nora the Nurse",
        "Oliver the Ornithologist", "Penelope the Painter", "Quincy the Queen", "Ryan the Rock Climber", "Sophia the Soccer Player",
        "Thomas the Teacher", "Ursula the Umpire", "Violet the Veterinarian", "Wyatt the Writer", "Xander the Xylophonist",
        "Yara the Yoga Instructor", "Zach the Zookeeper", "Adam the Astronaut", "Beth the Baker", "Charlie the Chef",
        "Daisy the Dancer", "Ethan the Engineer", "Fiona the Fisherman", "George the Gardener", "Holly the Historian",
        "Ian the Inventor", "Jasmine the Juggler", "Kevin the King", "Lily the Linguist", "Max the Magician",
        "Nora the Nurse", "Oscar the Ornithologist", "Penelope the Painter", "Quincy the Queen", "Ryan the Rockstar",
        "Sophia the Scientist", "Thomas the Teacher", "Ursula the Umpire", "Vincent the Veterinarian", "Willow the Writer",
        "Xavier the Xylophonist", "Yara the Yoga Instructor", "Zara the Zoologist", "Arthur the Astronomer", "Bella the Baker",
        "Caleb the Coach", "Diana the Dancer", "Eli the Engineer", "Fiona the Farmer", "George the Gardener",
        "Hannah the Historian", "Isaac the Illustrator", "Jasmine the Juggler", "Kevin the King", "Luna the Librarian",
        "Max the Magician", "Nora the Nurse", "Oscar the Ornithologist", "Penelope the Painter", "Quincy the Queen",
        "Ryan the Rock Climber", "Sophia the Scientist", "Thomas the Teacher", "Ursula the Umpire", "Vincent the Veterinarian",
        "Willow the Writer", "Xavier the Xylophonist", "Yara the Yoga Instructor", "Zara the Zoologist"
        // Continue with more names...
    ]
    
    // Button values for WhatView
    let whatButtonValues: [String] = [
        "Admiring Art", "Building a Sandcastle", "Catching Butterflies", "Digging for Dinosaurs",
        // Continue with other values
    ]
    
    // Button values for WhereView
    let whereButtonValues: [String] = [
        "At the Amusement Park", "By the Beach", "In the Clouds", "Deep in the Jungle",
        // Continue with other values
    ]
    
    // Button values for WhenView
    let whenButtonValues: [String] = [
        "During a Full Moon", "At the Break of Dawn", "When Dinosaurs Roamed", "In the Future",
        // Continue with other values
    ]
    
    @Published var whoSelectedValues: [String] = []
    @Published var whatSelectedValues: [String] = []
    @Published var whereSelectedValues: [String] = []
    @Published var whenSelectedValues: [String] = []
    @Published var selectedButton: String?
    
    // Button formats and animations
    let buttonShadowRadius: CGFloat = 2
    let buttonShadowXOffset: CGFloat = 0
    let buttonShadowYOffset: CGFloat = 2
    let buttonScaleEffectOnTap: CGFloat = 1.2
    
    // Styling for main button
    func styleMainButton(_ title: String) -> some View {
        Text(title)
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(Color("textColor"))
            .font(.headline)
            .background(Color("buttonColor"))
            .cornerRadius(25)
            .shadow(radius: buttonShadowRadius, x: buttonShadowXOffset, y: buttonShadowYOffset)
            .scaleEffect(buttonScaleEffectOnTap)
            .animation(.easeInOut, value: buttonScaleEffectOnTap)
    }
    
    // Call this method to reset all selections
    func resetValues() {
        whoSelectedValues.removeAll()
        whatSelectedValues.removeAll()
        whereSelectedValues.removeAll()
        whenSelectedValues.removeAll()
        selectedButton = nil
    }
}

struct BigButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title)
            .foregroundColor(Color("textColor"))
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .background(Color("buttonColor"))
            .cornerRadius(25)
            .shadow(color: Color("selectedButtonColor"), radius: 10, x: 0, y: 0)
            .scaleEffect(configuration.isPressed ? CGFloat(1.2) : 1.0)
            .animation(.easeInOut)
    }
}

struct CustomTextModifier: ViewModifier {
    var selectedValue: String?
    var value: String
    
    func body(content: Content) -> some View {
        content
            .fontWeight(.semibold)
            .foregroundColor(Color("textColor"))
            .font(.title2)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 60, maxHeight: 60)
            .padding()
            .background(selectedValue == value ? Color("selectedButtonColor") : Color("buttonColor"))
            .cornerRadius(30)
            .shadow(color: Color("selectedButtonColor"), radius: 10, x: 0, y: 0)
    }
}

extension Text {
    func customTextStyle(selectedValue: String?, value: String) -> some View {
        self.modifier(CustomTextModifier(selectedValue: selectedValue, value: value))
    }
}
