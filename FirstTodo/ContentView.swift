import SwiftUI
import UserNotifications
import CoreML

// MARK: - 카테고리 Enum
enum TodoCategory: String, CaseIterable {
    case shopping = "쇼핑"
    case meeting = "회의"
    case workout = "운동"
    case others = "기타"
    
    var icon: String {
        switch self {
        case .shopping: return "🛒"
        case .meeting: return "📅"
        case .workout: return "🏋️"
        case .others: return ""
        }
    }
    
    var color: Color {
        switch self {
        case .shopping: return .blue
        case .meeting: return .purple
        case .workout: return .green
        case .others: return .primary
        }
    }
}

// MARK: - Todo 모델
struct TodoItem: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let category: String
    var isDone: Bool = false
    let dateAdded: Date
    let targetDate: Date?
}

struct ContentView: View {
    @State private var newTodo: String = ""
    @State private var todoList: [TodoItem] = [] {
        didSet {
            saveTodoList()
            updateBadgeCount()
        }
    }
    @State private var motivationMessage: String = ""
    @State private var showTodayOnly: Bool = false
    @State private var todayRecommendation: String? = nil
    @State private var selectedTargetDate: Date = Date()

    @AppStorage("reminderTime") private var reminderTime: Double = 5.0

    private let todoListKey = "TodoList"

    let motivationMessages = [
        "좋아요! 한 걸음 더 나아갔어요 💪",
        "계획은 실행될 때 의미가 있어요 🚀",
        "지금 시작하면 내일이 달라져요 ✨",
        "포기하지 마세요, 계속 가세요 🛤️"
    ]
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 입력 영역
                    VStack {
                        HStack {
                            TextField("할 일을 입력하세요", text: $newTodo, onCommit: { addTodo() })
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 200)

                            Button("추가하기") { addTodo() }
                                .disabled(newTodo.isEmpty)
                                .padding(.horizontal)
                                .background(newTodo.isEmpty ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        // 목표 날짜 선택
                        DatePicker("목표 날짜", selection: $selectedTargetDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding(.horizontal)
                    }
                    .padding()

                    // 동기부여 메시지
                    if !motivationMessage.isEmpty {
                        Text(motivationMessage)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    // 오늘만 보기 토글
                    Toggle("오늘 예정된 할 일만 보기", isOn: $showTodayOnly)
                        .padding()

                    // 오늘의 추천
                    if let recommendation = todayRecommendation {
                        Text("👉 오늘의 추천: \(recommendation)")
                            .font(.headline)
                            .padding()
                    }

                    Button("오늘의 추천 뽑기") {
                        pickTodayRecommendation()
                    }
                    .padding(.bottom)

                    // Todo 리스트
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(groupedTodos.keys.sorted(by: sortCategories), id: \.self) { category in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(category)
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(groupedTodos[category] ?? []) { todo in
                                    let cat = TodoCategory(rawValue: todo.category) ?? .others
                                    HStack {
                                        Button(action: { toggleDone(todo) }) {
                                            Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                                        }
                                        .buttonStyle(BorderlessButtonStyle())

                                        if !cat.icon.isEmpty {
                                            Text(cat.icon)
                                        }

                                        VStack(alignment: .leading) {
                                            Text(todo.text)
                                                .strikethrough(todo.isDone)
                                                .opacity(todo.isDone ? 0.4 : 1.0)

                                            if let targetDate = todo.targetDate {
                                                Text(formatDate(targetDate))
                                                    .font(.caption)
                                                    .foregroundColor(targetDate < Date() && !todo.isDone ? .red : .gray)
                                            }
                                        }
                                        Spacer()

                                        Button(action: {
                                            if let index = todoList.firstIndex(where: { $0.id == todo.id }) {
                                                todoList.remove(at: index)
                                            }
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                    .foregroundColor(cat.color)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .padding(.horizontal)

                    // 완료 통계
                    if !todoList.isEmpty {
                        Text("완료: \(completedCount) / \(todoList.count) (\(completionRate, specifier: "%.1f")%)")
                            .font(.caption)
                            .padding()
                    }
                }
                .padding()
                .navigationTitle("오늘의 할 일")
                .toolbar {
                    NavigationLink(destination: SettingsView(reminderTime: $reminderTime)) {
                        Text("설정")
                    }
                }
                .onAppear {
                    loadTodoList()
                    cleanOldTodos()
                    requestNotificationPermission()
                    updateBadgeCount()
                }
            }
        }
    }

    // MARK: - Todo 추가
    func addTodo() {
        guard !newTodo.isEmpty else { return }

        let predictedCategory = ToDoMLPredictor.shared.predict(newTodo) ?? "기타"
        let newItem = TodoItem(id: UUID(), text: newTodo, category: predictedCategory, dateAdded: Date(), targetDate: selectedTargetDate)
        todoList.append(newItem)
        newTodo = ""

        motivationMessage = motivationMessages.randomElement() ?? ""
        scheduleNotification(for: newItem)
    }

    // MARK: - 완료 토글
    func toggleDone(_ todo: TodoItem) {
        if let index = todoList.firstIndex(where: { $0.id == todo.id }) {
            todoList[index].isDone.toggle()
        }
    }

    // MARK: - 삭제
    func deleteTodo(category: String, at offsets: IndexSet) {
        if let index = groupedTodos[category]?.indices.first(where: { offsets.contains($0) }) {
            let flatIndex = todoList.firstIndex(where: { $0.id == groupedTodos[category]![index].id })
            if let flatIndex = flatIndex {
                todoList.remove(at: flatIndex)
            }
        }
    }

    // MARK: - 저장/불러오기
    func saveTodoList() {
        if let encoded = try? JSONEncoder().encode(todoList) {
            UserDefaults.standard.set(encoded, forKey: todoListKey)
        }
    }

    func loadTodoList() {
        if let data = UserDefaults.standard.data(forKey: todoListKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            todoList = decoded
        }
    }

    // MARK: - 오래된 완료 Todo 정리
    func cleanOldTodos() {
        todoList.removeAll { $0.isDone }
    }

    // MARK: - 오늘 필터
    var filteredTodos: [TodoItem] {
        if showTodayOnly {
            return todoList.filter {
                if let target = $0.targetDate {
                    return Calendar.current.isDateInToday(target)
                }
                return false
            }
        } else {
            return todoList
        }
    }

    var groupedTodos: [String: [TodoItem]] {
        Dictionary(grouping: sortedTodos) { $0.category }
    }

    var sortedTodos: [TodoItem] {
        filteredTodos.sorted {
            if $0.isDone == $1.isDone {
                return $0.dateAdded < $1.dateAdded
            }
            return !$0.isDone && $1.isDone
        }
    }

    func sortCategories(_ lhs: String, _ rhs: String) -> Bool {
        let order = TodoCategory.allCases.map { $0.rawValue }
        return (order.firstIndex(of: lhs) ?? order.count) < (order.firstIndex(of: rhs) ?? order.count)
    }

    // MARK: - 통계
    var completedCount: Int {
        todoList.filter { $0.isDone }.count
    }

    var completionRate: Double {
        guard !todoList.isEmpty else { return 0 }
        return (Double(completedCount) / Double(todoList.count)) * 100
    }

    // MARK: - 오늘의 추천
    func pickTodayRecommendation() {
        let todays = filteredTodos.filter { !$0.isDone }
        todayRecommendation = todays.randomElement()?.text ?? "오늘 할 일이 없어요 🎉"
    }

    // MARK: - 날짜 포맷
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - 알림
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleNotification(for todo: TodoItem) {
        let content = UNMutableNotificationContent()
        content.title = "할 일 리마인드"
        content.body = "\(todo.text)을(를) 잊지 마세요!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: reminderTime * 60, repeats: false)
        let request = UNNotificationRequest(identifier: todo.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 아이콘 뱃지
    func updateBadgeCount() {
        UIApplication.shared.applicationIconBadgeNumber = todoList.filter { !$0.isDone }.count
    }
}

// MARK: - 설정화면
struct SettingsView: View {
    @Binding var reminderTime: Double

    var body: some View {
        Form {
            Section(header: Text("알림 설정")) {
                VStack(alignment: .leading) {
                    Text("알림 시간 (분 후)")
                    Slider(value: $reminderTime, in: 1...1440, step: 1)
                    Text("\(Int(reminderTime))분 후에 알림")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("설정")
    }
}

// MARK: - ML 예측 싱글톤
class ToDoMLPredictor {
    static let shared = ToDoMLPredictor()
    let model: ToDoML_1

    private init() {
        model = try! ToDoML_1(configuration: MLModelConfiguration())
    }

    func predict(_ text: String) -> String? {
        return try? model.prediction(text: text).label
    }
}

#Preview {
    ContentView()
}
