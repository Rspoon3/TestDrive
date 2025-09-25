import SwiftUI

struct TranscriptionDetailView: View {
    @State var entry: TranscriptionEntry
    let store: TranscriptionStore
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @State private var editedText: String = ""

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                if isEditing {
                    TextField("Title", text: $editedTitle)
                        .font(.title2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    Text(entry.title)
                        .font(.title2)
                        .bold()
                }

                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if entry.hasAudioFile, let audioURL = entry.url {
                    AudioPlayerView(audioURL: audioURL)
                        .padding(.vertical, 8)
                }

                Divider()

                if isEditing {
                    TextEditor(text: $editedText)
                        .font(.body)
                } else {
                    ScrollView {
                        Text(entry.text)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Transcription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if isEditing {
                            Button("Cancel") {
                                cancelEditing()
                            }
                            Button("Save") {
                                saveChanges()
                            }
                        } else {
                            Menu {
                                Button("Edit") {
                                    startEditing()
                                }
                                Button("Delete", role: .destructive) {
                                    deleteTranscription()
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            editedTitle = entry.title
            editedText = String(entry.text.characters)
        }
    }

    private func startEditing() {
        isEditing = true
    }

    private func cancelEditing() {
        isEditing = false
        editedTitle = entry.title
        editedText = String(entry.text.characters)
    }

    private func saveChanges() {
        entry.title = editedTitle
        entry.text = AttributedString(editedText)
        store.updateTranscription(entry)
        isEditing = false
    }

    private func deleteTranscription() {
        entry.deleteAudioFile()
        store.deleteTranscription(entry)
        dismiss()
    }
}