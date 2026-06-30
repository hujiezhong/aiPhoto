import SwiftUI
import AVFoundation

struct RootView: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel

    @State private var showingSettings = false

    var body: some View {
        CameraView(viewModel: cameraViewModel, previewLayer: cameraViewModel.previewLayer)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: settingsViewModel)
            }
    }
}