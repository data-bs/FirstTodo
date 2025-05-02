import SwiftUI

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
                    Text(todo)
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
}

#Preview {
    ContentView()
}
