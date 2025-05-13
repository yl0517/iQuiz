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

struct Question: Identifiable {
    let id = UUID()
    let text: String
    let options: [String]
    let correctIndex: Int
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

let quizQuestions: [String: [Question]] = [
    "Mathematics": [
        Question(text: "What's 9 + 4?", options: ["3", "13", "23"], correctIndex: 1),
        Question(text: "What is 5 - 3?", options: ["2", "8", "1"], correctIndex: 0),
        Question(text: "Who created the Pythagorean Theorem?", options: ["Python", "Pytorch", "Pythagoras"], correctIndex: 2),
        Question(text: "The Poincaré Conjecture has been...", options: ["Solved", "Unsolved", "What is that"], correctIndex: 0)
    ],
    "Marvel Super Heroes": [
        Question(text: "Why can Thor lift Mjolnir?", options: ["Mjolnir has his fingerprint on it", "Physics", "He is worthy"], correctIndex: 2),
        Question(text: "How many infinity stones did Thanos collect?", options: ["3", "11", "6"], correctIndex: 2),
        Question(text: "Radiation of the infinity gauntlet is mostly...", options: ["Gamma", "Alpha", "Omega"], correctIndex: 0),
        Question(text: "Captain's sheild is made out of...", options: ["Vibranium", "Adamantium", "Plastic"], correctIndex: 0),
        Question(text: "Who here is something of a scientist himself?", options: ["Drax", "Norman Osborn", "Peter Quiil"], correctIndex: 1)
    ],
    "Science": [
        Question(text: "The Mitochondria is...", options: ["The powerhouse of the cell", "The house of the cell", "The hose of the cell"], correctIndex: 0),
        Question(text: "Who defined Gravity?", options: ["Newton", "Oppenheimer", "Einstein"], correctIndex: 0),
        Question(text: "Who introduced the theory of relativity?", options: ["Patrick Star", "Albert Einstein", "Tony Stark"], correctIndex: 1)
    ]
]

struct ContentView: View {
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            List(quizTopics) { topic in
                NavigationLink(destination: QuizView(topic: topic)) {
                    QuizRow(topic: topic)
                }
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

struct QuizView: View {
    let topic: QuizTopic
    @Environment(\.presentationMode) var presentationMode
    @State private var questions: [Question]
    @State private var currentIndex = 0
    @State private var selectedOption: Int? = nil
    @State private var score = 0
    @State private var showAnswer = false

    init(topic: QuizTopic) {
        self.topic = topic
        self._questions = State(initialValue: quizQuestions[topic.title] ?? [])
    }

    var body: some View {
        VStack {
            if currentIndex < questions.count {
                if !showAnswer {
                    questionScene
                } else {
                    answerScene
                }
            } else {
                finishedScene
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .navigationTitle(topic.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }
        }
    }

    var questionScene: some View {
        VStack(spacing: 20) {
            Text(questions[currentIndex].text)
                .font(.title2)
            ForEach(0..<questions[currentIndex].options.count, id: \ .self) { idx in
                Button(action: { selectedOption = idx }) {
                    Text(questions[currentIndex].options[idx])
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedOption == idx ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            Button("Submit") {
                submitAnswer()
            }
            .disabled(selectedOption == nil)
            .padding(.top)
            .gesture(DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width > 0 {
                        submitAnswer()
                    }
                })
        }
    }

    var answerScene: some View {
        VStack(spacing: 20) {
            Text(questions[currentIndex].text)
                .font(.title2)
            Text("Answer: \(questions[currentIndex].options[questions[currentIndex].correctIndex])")
                .foregroundColor(.black)
            Text(selectedOption == questions[currentIndex].correctIndex ? "Correct!" : "Incorrect.")
                .font(.headline)
            Button("Next") {
                advance()
            }
            .gesture(DragGesture(minimumDistance: 50)
            .onEnded { v in if v.translation.width > 0 { advance() } })
        }
    }

    var finishedScene: some View {
        VStack(spacing: 20) {
            Text(resultText).font(.largeTitle)
            Text("Score: \(score) of \(questions.count)")
            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding(.top)
        }
    }

    private func submitAnswer() {
        guard let choice = selectedOption else { return }
        if choice == questions[currentIndex].correctIndex {
            score += 1
        }
        showAnswer = true
    }

    private func advance() {
        currentIndex += 1
        selectedOption = nil
        showAnswer = false
    }

    private var resultText: String {
        switch score {
        case questions.count: 
            return "Perfect"
        case (questions.count/2)..<questions.count:
            return "Not bad"
        default: return "Not even close"
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
