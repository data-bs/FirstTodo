import SwiftUI
import CoreML

struct ContentView: View {
    @State private var newTodo: String = ""
    @State private var todoList: [String] = [] {
        didSet {
            saveTodoList()
        }
    }

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
                .padding(.horizontal)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()

            List {
                ForEach(todoList, id: \.self) { todo in
                    let (icon, color) = iconAndColor(for: todo)

                    HStack {
                        Text(icon)
                        Text(todo)
                    }
                    .foregroundColor(color)
                }
                .onDelete(perform: deleteTodo)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            loadTodoList()
        }
    }

    // 할 일 추가하기
    func addTodo() {
        if !newTodo.isEmpty {
            todoList.append(newTodo)
            newTodo = ""
        }
    }

    // 할 일 삭제하기
    func deleteTodo(at offsets: IndexSet) {
        todoList.remove(atOffsets: offsets)
    }

    // 저장하기
    func saveTodoList() {
        UserDefaults.standard.set(todoList, forKey: "TodoList")
    }

    // 불러오기
    func loadTodoList() {
        if let savedTodos = UserDefaults.standard.stringArray(forKey: "TodoList") {
            todoList = savedTodos
        }
    }

    // ML을 통한 카테고리 분류 및 색/아이콘 결정
    func iconAndColor(for todo: String) -> (String, Color) {
        // ML 모델 예측
        guard let model = try? ToDoML_1(configuration: MLModelConfiguration()),
              let prediction = try? model.prediction(text: todo) else {
            return ("", .primary)
        }

        // 예측 결과(label)에 따라 아이콘과 색 설정
        switch prediction.label {
        case "쇼핑":
            return ("🛒", .blue)
        case "회의":
            return ("📅", .purple)
        case "운동":
            return ("🏋️", .green)
        default:
            return ("", .primary)
        }
    }
}

#Preview {
    ContentView()
}
