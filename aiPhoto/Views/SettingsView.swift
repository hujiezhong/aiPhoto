import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("模型") {
                    Picker("选择模型", selection: $viewModel.selectedModel) {
                        ForEach(ModelKind.allCases, id: \.self) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("API Key") {
                    SecureField("sk-...", text: $viewModel.apiKey)
                }

                Section("拍摄") {
                    Toggle("对齐后自动拍照", isOn: $viewModel.autoCapture)
                    VStack(alignment: .leading) {
                        Text("对齐阈值: \(String(format: "%.2f", viewModel.alignmentThreshold))")
                        Slider(value: $viewModel.alignmentThreshold, in: 0.01...0.20, step: 0.01)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        viewModel.save()
                        dismiss()
                    }
                }
            }
        }
    }
}