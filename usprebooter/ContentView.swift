//
//  ContentView.swift
//  usprebooter
//
//  Created by LL on 29/11/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Button("go") {
                fuck()
//                copyLaunchd()
//                userspaceReboot()
            }
            Button("uspreboot") {
//                fuck()
//                copyLaunchd()
                userspaceReboot()
            }
        }
    }
}

//#Preview {
//    ContentView()
//}
