import CoreML

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
