//
//  StoryBuilderView.swift
//  WonderSproutsApp_v4
//
//  Created by Charles Atchison on 7/20/23.
//

import SwiftUI

struct StoryBuilderView: View {
    @State private var selectedWho: String?
    @State private var selectedWhat: String?
    @State private var selectedWhere: String?
    @State private var selectedWhen: String?
    
    var selections: [(text: String, view: AnyView, binding: () -> Binding<String?>)] {
        [
            ("Who is going with you?", AnyView(WhoView(selected: selectedWhoBinding)), { self.selectedWhoBinding }),
            ("What are you doing?", AnyView(WhatView(selected: selectedWhatBinding)), { self.selectedWhatBinding }),
            ("Where are you going?", AnyView(WhereView(selected: selectedWhereBinding)), { self.selectedWhereBinding }),
            ("When are you going?", AnyView(WhenView(selected: selectedWhenBinding)), { self.selectedWhenBinding })
        ]
    }
    
    var selectedWhoBinding: Binding<String?> { $selectedWho }
    var selectedWhatBinding: Binding<String?> { $selectedWhat }
    var selectedWhereBinding: Binding<String?> { $selectedWhere }
    var selectedWhenBinding: Binding<String?> { $selectedWhen }
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
            NavigationView {
                ZStack {
                    Image("background_image")
                        .resizable()
                        .ignoresSafeArea()
                    
                    // Main VStack containing the NavigationLinks
                    VStack(spacing: 20) {
                        ForEach(selections, id: \.text) { item in
                            NavigationLink(destination: item.view) {
                                Text(item.binding().wrappedValue ?? item.text)
                                    .customTextStyle(selectedValue: item.binding().wrappedValue, value: item.text)
                            }
                        }
                    }
                    .padding()
                    
                    // VStack just for the title, positioned at the very top
                    VStack {
                        Text("Story Builder")
                            .font(.title)
                            .padding(.top, 5) // Adjust to move the title closer or further from the top
                        Spacer() // Push the title to the top
                    }
                    
                    // VStack to push the HStack with buttons to the bottom
                    VStack {
                        Spacer()
                        HStack {
                            Button(action: {
                                // Navigate back to ContentView
                                self.presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Back")
                                    .modifier(ButtonModifier()) // Assuming you have ButtonModifier similar to CustomPickerView
                            }
                            .padding(.leading, 20)
                            
                            Spacer()
                            
                            Button(action: {
                                // Implement your build story action here
                            }) {
                                Text("Build Story!")
                                    .modifier(ButtonModifier()) // Assuming you have ButtonModifier similar to CustomPickerView
                            }
                            .padding(.trailing, 20)
                        }
                        .padding(.bottom, 20)
                        
                    }
                }.edgesIgnoringSafeArea(.bottom)
            }
        }
    }

struct WhoView: View {
    @Binding var selected: String?
    let appTheme = AppTheme()

    var body: some View {
        CustomPickerView(
            buttonValues: appTheme.whoButtonValues,
            selectedValue: $selected,
            title: "Who is going with you?",
            appTheme: appTheme
        )
    }
}

struct WhatView: View {
    @Binding var selected: String?
    let appTheme = AppTheme()

    var body: some View {
        CustomPickerView(
            buttonValues: appTheme.whatButtonValues,
            selectedValue: $selected,
            title: "What are you doing?",
            appTheme: appTheme
        )
    }
}

struct WhereView: View {
    @Binding var selected: String?
    let appTheme = AppTheme()

    var body: some View {
        CustomPickerView(
            buttonValues: appTheme.whereButtonValues,
            selectedValue: $selected,
            title: "Where are you going?",
            appTheme: appTheme
        )
    }
}

struct WhenView: View {
    @Binding var selected: String?
    let appTheme = AppTheme()

    var body: some View {
        CustomPickerView(
            buttonValues: appTheme.whenButtonValues,
            selectedValue: $selected,
            title: "When are you going?",
            appTheme: appTheme
        )
    }
}


struct StoryBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        StoryBuilderView()
    }
}

