import SwiftUI

struct SettingsView: View {
    @Binding var isShowModeActive: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $isShowModeActive) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(.orange)
                                Text("Show Mode")
                                    .font(.headline)
                            }
                            Text("Camera-first mode for live events")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.orange)
                } header: {
                    Text("Event Settings")
                }

                if isShowModeActive {
                    Section {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.blue)
                            Text("Event Started")
                            Spacer()
                            Text("Active")
                                .font(.caption)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .clipShape(Capsule())
                        }

                        HStack {
                            Image(systemName: "eye.fill")
                                .foregroundStyle(.orange)
                            Text("Cards on Display")
                            Spacer()
                            Text("342")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Show Status")
                    }
                }

                Section {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
