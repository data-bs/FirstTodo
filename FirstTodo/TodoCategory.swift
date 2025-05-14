import SwiftUI

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
