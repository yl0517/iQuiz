//
//  ContentView.swift
//  iQuiz
//
//  Created by Yoobin Lee on 5/3/25.
//

import SwiftUI

struct QuizTopic: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
}

let quizTopics: [QuizTopic] = [
    QuizTopic(title: "Mathematics",
              description: "Lets see if you know your numbers",
              iconName: "function"),
    QuizTopic(title: "Marvel Super Heroes",
              description: "Iron Man > Captain America",
              iconName: "figure.boxing"),
    QuizTopic(title: "Science",
              description: "Who REALLY enjoyed Gen Sci at UW",
              iconName: "flask")
]

struct ContentView: View {
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            List(quizTopics) { topic in
                QuizRow(topic: topic)
            }
            .navigationTitle("Quizzes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .alert("Settings go here", isPresented: $showSettings) {
                Button("OK", role: .cancel) { }
            }
        }
    }
}

struct QuizRow: View {
    let topic: QuizTopic
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: topic.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(topic.title)
                    .font(.headline)
                Text(topic.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
