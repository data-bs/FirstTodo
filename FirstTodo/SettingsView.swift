import SwiftUI

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
