//
//  ContentView.swift
//  iQuiz
//
//  Created by Yoobin Lee on 5/3/25.
//

import SwiftUI
import Combine

struct QuizTopic: Identifiable, Hashable {
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

struct RemoteQuiz: Decodable {
    let title: String
    let desc: String
    let questions: [RemoteQuestion]
}

struct RemoteQuestion: Decodable {
    let text: String
    let answers: [String]
    let answer: String
}

let defaultURL = "https://tednewardsandbox.site44.com/questions.json"

class QuizData: ObservableObject {
    @Published var topics: [QuizTopic] = []
    @Published var questionsMap: [String: [Question]] = [:]
    @Published var networkError: String?

    @AppStorage("quizSourceURL") var sourceURL: String = defaultURL
    @Published var refreshInterval: Int = UserDefaults.standard.integer(forKey: "refreshInterval") {
        didSet {
            UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
            scheduleTimer()
        }
    }

    private var timerCancellable: AnyCancellable?

    init() {
        scheduleTimer()
    }

    func fetchQuizzes() {
        guard let url = URL(string: sourceURL) else {
            networkError = "Invalid URL: \(sourceURL)"
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                if let err = error {
                    self.networkError = err.localizedDescription
                    return
                }
                guard let data = data else {
                    self.networkError = "No data received"
                    return
                }
                do {
                    let remote = try JSONDecoder().decode([RemoteQuiz].self, from: data)
                    self.topics = remote.map { quiz in
                        QuizTopic(title: quiz.title,
                                  description: quiz.desc,
                                  iconName: self.iconName(for: quiz.title))
                    }
                    var newMap: [String: [Question]] = [:]
                    for quiz in remote {
                        newMap[quiz.title] = quiz.questions.map { rq in
                            let idx = Int(rq.answer) ?? 0
                            return Question(text: rq.text,
                                            options: rq.answers,
                                            correctIndex: idx)
                        }
                    }
                    self.questionsMap = newMap
                } catch {
                    self.networkError = error.localizedDescription
                }
            }
        }.resume()
    }

    private func scheduleTimer() {
        timerCancellable?.cancel()
        guard refreshInterval > 0 else { return }
        timerCancellable = Timer.publish(every: TimeInterval(refreshInterval * 60), on: .main, in: .common)
            .autoconnect()
            .sink { _ in self.fetchQuizzes() }
    }

    private func iconName(for title: String) -> String {
        switch title {
        case "Mathematics": return "function"
        case "Marvel Super Heroes": return "figure.boxing"
        case "Science": return "flask"
        default: return "questionmark.circle"
        }
    }
}

struct ContentView: View {
    @StateObject private var data = QuizData()
    @State private var showingSettings = false
    @State private var showingErrorAlert = false

    var body: some View {
        NavigationView {
            List(data.topics, id: \.self) { topic in
                NavigationLink(destination: QuizView(topic: topic)
                                .environmentObject(data)) {
                    QuizRow(topic: topic)
                }
            }
            .navigationTitle("Quizzes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(data: data)
            }
            .refreshable { data.fetchQuizzes() }
            .onReceive(data.$networkError) { err in showingErrorAlert = (err != nil) }
            .alert("Network Error", isPresented: $showingErrorAlert, presenting: data.networkError) { _ in
                Button("OK") { data.networkError = nil }
            } message: { msg in Text(msg) }
            .onAppear { data.fetchQuizzes() }
        }
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var data: QuizData
    @State private var intervalText: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Data Source URL")) {
                    TextField("Quiz JSON URL", text: $data.sourceURL)
                        .keyboardType(.URL)
                    Button("Check Now") { data.fetchQuizzes() }
                }
                Section(header: Text("Refresh Interval (minutes)")) {
                    TextField("e.g., 30", text: $intervalText)
                        .keyboardType(.numberPad)
                    Button("Set Interval") {
                        if let min = Int(intervalText), min >= 0 {
                            data.refreshInterval = min
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
}

struct QuizRow: View {
    let topic: QuizTopic
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: topic.iconName)
                .resizable().scaledToFit().frame(width: 40, height: 40).foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(topic.title).font(.headline)
                Text(topic.description).font(.subheadline).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct QuizView: View {
    let topic: QuizTopic
    @EnvironmentObject var data: QuizData
    @Environment(\.presentationMode) var presentationMode
    @State private var currentIndex = 0
    @State private var selectedOption: Int? = nil
    @State private var score = 0
    @State private var showAnswer = false

    var questions: [Question] { data.questionsMap[topic.title] ?? [] }

    var body: some View {
        VStack {
            if currentIndex < questions.count {
                if !showAnswer { questionScene } else { answerScene }
            } else { finishedScene }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .navigationTitle(topic.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left"); Text("Back")
                }
            }
        }
    }

    var questionScene: some View {
        VStack(spacing: 20) {
            Text(questions[currentIndex].text).font(.title2)
            ForEach(0..<questions[currentIndex].options.count, id: \.self) { idx in
                Button { selectedOption = idx } label: {
                    Text(questions[currentIndex].options[idx])
                        .padding().frame(maxWidth: .infinity)
                        .background(selectedOption == idx ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            Button("Submit") { submitAnswer() }
                .disabled(selectedOption == nil)
                .padding(.top)
                .gesture(DragGesture(minimumDistance: 50).onEnded {
                    if $0.translation.width > 0 { submitAnswer() }
                    else if $0.translation.width < 0 { presentationMode.wrappedValue.dismiss() }
                })
        }
    }

    var answerScene: some View {
        VStack(spacing: 20) {
            Text(questions[currentIndex].text).font(.title2)
            Text("Answer: \(questions[currentIndex].options[questions[currentIndex].correctIndex])")
            Text(selectedOption == questions[currentIndex].correctIndex ? "Correct!" : "Incorrect.")
                .font(.headline)
            Button("Next") { advance() }
                .gesture(DragGesture(minimumDistance: 50).onEnded {
                    if $0.translation.width > 0 { advance() }
                    else if $0.translation.width < 0 { presentationMode.wrappedValue.dismiss() }
                })
        }
    }

    var finishedScene: some View {
        VStack(spacing: 20) {
            Text(resultText).font(.largeTitle)
            Text("Score: \(score) of \(questions.count)")
            Button("Done") { presentationMode.wrappedValue.dismiss() }
                .padding(.top)
        }
    }

    private func submitAnswer() {
        guard let choice = selectedOption else { return }
        if choice == questions[currentIndex].correctIndex { score += 1 }
        showAnswer = true
    }

    private func advance() {
        currentIndex += 1
        selectedOption = nil
        showAnswer = false
    }

    private var resultText: String {
        switch score {
        case questions.count: return "Perfect"
        case (questions.count/2)..<questions.count: return "Not bad"
        default: return "Not even close"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
