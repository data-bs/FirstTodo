import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TodoViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 입력 영역
                    VStack {
                        HStack {
                            TextField("할 일을 입력하세요", text: $viewModel.newTodo, onCommit: {
                                viewModel.addTodo()
                            })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)

                            
                            Button("추가하기") {
                                viewModel.addTodo()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.newTodo.isEmpty)
                        }

                        // 목표 날짜 선택
                        DatePicker("목표 날짜", selection: $viewModel.selectedTargetDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding(.horizontal)
                    }
                    .padding()

                    // 동기부여 메시지
                    if !viewModel.motivationMessage.isEmpty {
                        Text(viewModel.motivationMessage)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    // 오늘만 보기 토글
                    Toggle("오늘 예정된 할 일만 보기", isOn: $viewModel.showTodayOnly)
                        .padding()

                    // 오늘의 추천
                    if let recommendation = viewModel.todayRecommendation {
                        Text("👉 오늘의 추천: \(recommendation)")
                            .font(.headline)
                            .padding()
                    }

                    Button("오늘의 추천 뽑기") {
                        viewModel.pickTodayRecommendation()
                    }
                    .padding(.bottom)

                    // Todo 리스트
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.groupedTodos.keys.sorted(by: viewModel.sortCategories), id: \.self) { category in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(category)
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(viewModel.groupedTodos[category] ?? []) { todo in
                                    let cat = TodoCategory(rawValue: todo.category) ?? .others
                                    HStack {
                                        Button(action: {
                                            viewModel.toggleDone(todo)
                                        }) {
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
                                                Text(viewModel.formatDate(targetDate))
                                                    .font(.caption)
                                                    .foregroundColor(targetDate < Date() && !todo.isDone ? .red : .gray)
                                            }
                                        }
                                        Spacer()

                                        Button(action: {
                                            viewModel.deleteTodo(todo)
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
                    if !viewModel.todoList.isEmpty {
                        Text("완료: \(viewModel.completedCount) / \(viewModel.todoList.count) (\(viewModel.completionRate, specifier: "%.1f")%)")
                            .font(.caption)
                            .padding()
                    }
                }
                .padding()
                .navigationTitle("오늘의 할 일")
                .toolbar {
                    NavigationLink(destination: SettingsView(reminderTime: $viewModel.reminderTime)) {
                        Text("설정")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
