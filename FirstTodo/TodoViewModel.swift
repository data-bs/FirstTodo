import SwiftUI
import UserNotifications

class TodoViewModel: ObservableObject {
    @Published var todoList: [TodoItem] = [] {
        didSet {
            saveTodoList()
            updateBadgeCount()
        }
    }
    @Published var newTodo: String = ""
    @Published var motivationMessage: String = ""
    @Published var showTodayOnly: Bool = false
    @Published var todayRecommendation: String? = nil
    @Published var selectedTargetDate: Date = Date()
    
    @AppStorage("reminderTime") var reminderTime: Double = 5.0

    private let todoListKey = "TodoList"

    let motivationMessages = [
        "좋아요! 한 걸음 더 나아갔어요 💪",
        "계획은 실행될 때 의미가 있어요 🚀",
        "지금 시작하면 내일이 달라져요 ✨",
        "포기하지 마세요, 계속 가세요 🛤️"
    ]
    
    init() {
        loadTodoList()
        cleanOldTodos()
        requestNotificationPermission()
        updateBadgeCount()
    }

    func addTodo() {
        guard !newTodo.isEmpty else { return }

        let predictedCategory = ToDoMLPredictor.shared.predict(newTodo) ?? "기타"
        let newItem = TodoItem(id: UUID(), text: newTodo, category: predictedCategory, dateAdded: Date(), targetDate: selectedTargetDate)
        todoList.append(newItem)
        newTodo = ""

        motivationMessage = motivationMessages.randomElement() ?? ""
        scheduleNotification(for: newItem)
    }

    func toggleDone(_ todo: TodoItem) {
        if let index = todoList.firstIndex(where: { $0.id == todo.id }) {
            todoList[index].isDone.toggle()
        }
    }

    func deleteTodo(_ todo: TodoItem) {
        if let index = todoList.firstIndex(where: { $0.id == todo.id }) {
            todoList.remove(at: index)
        }
    }

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

    func cleanOldTodos() {
        todoList.removeAll { $0.isDone }
    }

    func pickTodayRecommendation() {
        let todays = filteredTodos.filter { !$0.isDone }
        todayRecommendation = todays.randomElement()?.text ?? "오늘 할 일이 없어요 🎉"
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

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

    func updateBadgeCount() {
        UIApplication.shared.applicationIconBadgeNumber = todoList.filter { !$0.isDone }.count
    }

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

    var sortedTodos: [TodoItem] {
        filteredTodos.sorted {
            if $0.isDone == $1.isDone {
                return $0.dateAdded < $1.dateAdded
            }
            return !$0.isDone && $1.isDone
        }
    }

    var groupedTodos: [String: [TodoItem]] {
        Dictionary(grouping: sortedTodos) { $0.category }
    }

    func sortCategories(_ lhs: String, _ rhs: String) -> Bool {
        let order = TodoCategory.allCases.map { $0.rawValue }
        return (order.firstIndex(of: lhs) ?? order.count) < (order.firstIndex(of: rhs) ?? order.count)
    }

    var completedCount: Int {
        todoList.filter { $0.isDone }.count
    }

    var completionRate: Double {
        guard !todoList.isEmpty else { return 0 }
        return (Double(completedCount) / Double(todoList.count)) * 100
    }
}
