//
//  ContentView.swift
//  TextFieldFomatAndValidate
//
//  Created by Yang Xu on 2021/10/11.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FormatAndValidateByIntrospectView()
                .tabItem {
                    Text("Introspect")
                }

            FormatAndValidateByPureSwiftUIView()
                .tabItem {
                    Text("SwiftUI")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
