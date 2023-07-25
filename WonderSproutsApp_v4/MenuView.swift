//
//  MenuView.swift
//  WonderSproutsApp_v4
//
//  Created by Charles Atchison on 7/23/23.
//

import SwiftUI

struct MenuView: View {
    var body: some View {
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
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
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
