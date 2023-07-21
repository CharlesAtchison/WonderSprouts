//
//  CustomPickerView.swift
//  WonderSproutsApp_v4
//
//  Created by Charles Atchison on 7/20/23.
//

import SwiftUI

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
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
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
                                        .foregroundColor(Color.white)
                                        .font(.title2)
                                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 60, maxHeight: 60)
                                        .padding()
                                        .background(self.selectedValue == value ? Color("buttonColor") : Color("selectedButtonColor"))
                                        .cornerRadius(30)
                                        .shadow(color: .gray, radius: 10, x: 0, y: 0)
                                }
                            }
                        }
                        .padding(.bottom, 0)
                    }
                }
                
                Spacer()

                // "OK" button at the bottom
                Button(action: {
                    print("OK Button Pressed!")
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("OK")
                        .fontWeight(.semibold)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 60, maxHeight: 60)
                        .background(Color.blue)
                        .cornerRadius(30)
                        .padding(.horizontal, 50)
                        .padding(.bottom, 50)
                }
            }
        }
    }
    
    private func buttonTapped(value: String) {
        if selectedValue == value {
            print("test")
            selectedValue = nil
        } else {
            selectedValue = value
        }
    }
}


struct CustomPickerView_Previews: PreviewProvider {
    @State static private var dummySelectedValue: String? = nil

    static var previews: some View {
        CustomPickerView(buttonValues: ["one", "two", "three"], selectedValue: $dummySelectedValue, title: "Who View", appTheme: AppTheme())
    }
}
