import SwiftUI
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
}

struct ContentView: View {
    @State private var newTodo: String = ""
    @State private var todoList: [TodoItem] = [] {
        didSet {
            saveTodoList()
        }
    }

    private let todoListKey = "TodoList"

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                TextField("할 일을 입력하세요", text: $newTodo, onCommit: {
                    addTodo()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)

                Button("추가하기") {
                    addTodo()
                }
                .disabled(newTodo.isEmpty)
                .padding(.horizontal)
                .background(newTodo.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()

            List {
                ForEach(groupedTodos.keys.sorted(by: sortCategories), id: \.self) { category in
                    Section(header: Text(category)) {
                        ForEach(groupedTodos[category] ?? []) { todo in
                            let cat = TodoCategory(rawValue: todo.category) ?? .others
                            HStack {
                                if !cat.icon.isEmpty {
                                    Text(cat.icon)
                                }
                                Text(todo.text)
                            }
                            .foregroundColor(cat.color)
                        }
                        .onDelete { indexSet in
                            deleteTodo(category: category, at: indexSet)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())

            Spacer()
        }
        .padding()
        .onAppear {
            loadTodoList()
        }
    }

    // MARK: - 추가하기
    func addTodo() {
        guard !newTodo.isEmpty else { return }

        let predictedCategory = ToDoMLPredictor.shared.predict(newTodo) ?? "기타"
        let newItem = TodoItem(id: UUID(), text: newTodo, category: predictedCategory)
        todoList.append(newItem)
        newTodo = ""
    }

    // MARK: - 삭제하기
    func deleteTodo(category: String, at offsets: IndexSet) {
        if let index = groupedTodos[category]?.indices.first(where: { offsets.contains($0) }) {
            let flatIndex = todoList.firstIndex(where: { $0.id == groupedTodos[category]![index].id })
            if let flatIndex = flatIndex {
                todoList.remove(at: flatIndex)
            }
        }
    }

    // MARK: - UserDefaults 저장/불러오기
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

    // MARK: - 카테고리 그룹화
    var groupedTodos: [String: [TodoItem]] {
        Dictionary(grouping: todoList) { $0.category }
    }

    func sortCategories(_ lhs: String, _ rhs: String) -> Bool {
        let order = TodoCategory.allCases.map { $0.rawValue }
        return (order.firstIndex(of: lhs) ?? order.count) < (order.firstIndex(of: rhs) ?? order.count)
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
