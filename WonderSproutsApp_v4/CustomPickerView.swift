//
//  CustomPickerView.swift
//  WonderSproutsApp_v4
//
//  Created by Charles Atchison on 7/20/23.
//


import SwiftUI

struct CustomPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    let buttonValues: [String]
    @Binding var selectedValue: String?
    var title: String
    var appTheme: AppTheme
    
    var body: some View {
        ZStack {
            Image("background_image")
                .resizable()
                .ignoresSafeArea()
            
            VStack {
                // Title at the top
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("textColor"))
                    .padding(.top, 20)  // Adjusted padding for the title
                
                Spacer()

                // A grid of selectable buttons.
                GeometryReader { geometry in
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(buttonValues, id: \.self) { value in
                                Button(action: {
                                    self.buttonTapped(value: value)
                                }) {
                                    Text(value)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color("textColor"))
                                        .font(.title2)
                                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 60, maxHeight: 60)
                                        .padding()
                                        .background(self.selectedValue == value ? Color("selectedButtonColor") : Color("buttonColor"))
                                        .cornerRadius(30)
                                        .shadow(color: Color("selectedButtonColor"), radius: 10, x: 0, y: 0)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Back")
                            .modifier(ButtonModifier())
                    }
                    
                    Button(action: {
                        print("Create my own!")
                    }) {
                        Text("Create my own!")
                            .modifier(ButtonModifier())
                            .frame(minWidth: 200)  // Adjusted width for the middle button
                            .padding(.horizontal, 10) // Adjusted padding for the longer text
                    }
                    
                    Button(action: {
                        print("OK Button Pressed!")
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("OK")
                            .modifier(ButtonModifier())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 20)
            }
            .edgesIgnoringSafeArea(.bottom)  // Making the VStack ignore the bottom safe area
        }.navigationBarBackButtonHidden(true)
    }

    
    private func buttonTapped(value: String) {
        if selectedValue == value {
            selectedValue = nil
        } else {
            selectedValue = value
        }
    }
}

struct ButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .fontWeight(.semibold)
            .font(.title2)
            .foregroundColor(Color("textColor"))
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 60, maxHeight: 60)
            .background(Color("buttonColor"))
            .cornerRadius(30)
            .shadow(color: Color("selectedButtonColor"), radius: 10, x: 0, y: 0)
    }
}

struct CustomPickerView_Previews: PreviewProvider {
    @State static private var dummySelectedValue: String? = nil

    static var previews: some View {
        CustomPickerView(buttonValues: ["one", "two", "three"], selectedValue: $dummySelectedValue, title: "Who View", appTheme: AppTheme())
    }
}
