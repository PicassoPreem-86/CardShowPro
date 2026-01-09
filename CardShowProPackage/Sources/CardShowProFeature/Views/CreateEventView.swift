import SwiftUI

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var eventName = ""
    @State private var venueName = ""
    @State private var boothNumber = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Event Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Event Details")
                            .font(.headline)

                        VStack(spacing: 16) {
                            CustomTextField(
                                icon: "calendar",
                                placeholder: "Event Name",
                                text: $eventName
                            )

                            CustomTextField(
                                icon: "building.2",
                                placeholder: "Venue Name",
                                text: $venueName
                            )

                            CustomTextField(
                                icon: "mappin.circle",
                                placeholder: "Booth Number (Optional)",
                                text: $boothNumber
                            )
                        }
                    }

                    Divider()

                    // Dates Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Event Dates")
                            .font(.headline)

                        VStack(spacing: 16) {
                            DateTimePickerField(
                                icon: "calendar.badge.clock",
                                label: "Start Date & Time",
                                date: $startDate
                            )

                            DateTimePickerField(
                                icon: "calendar.badge.checkmark",
                                label: "End Date & Time",
                                date: $endDate
                            )
                        }
                    }

                    Divider()

                    // Notes Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notes & Goals")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundStyle(.secondary)
                                Text("Additional notes or sales goals")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            TextEditor(text: $notes)
                                .frame(height: 120)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                    }

                    // Create Button
                    Button {
                        // Create event action
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Create Event")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(eventName.isEmpty || venueName.isEmpty)
                    .opacity(eventName.isEmpty || venueName.isEmpty ? 0.5 : 1.0)
                }
                .padding()
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

struct DatePickerField: View {
    let icon: String
    let label: String
    @Binding var date: Date

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            DatePicker(label, selection: $date, displayedComponents: .date)
                .labelsHidden()

            Spacer()

            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

struct DateTimePickerField: View {
    let icon: String
    let label: String
    @Binding var date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)

                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}
