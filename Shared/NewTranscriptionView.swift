import SwiftUI
import AVFoundation

struct NewTranscriptionView: View {
    let store: TranscriptionStore
    @Environment(\.dismiss) private var dismiss

    @State private var entry = TranscriptionEntry.blank()
    @State private var transcriber: SpokenWordTranscriber? = nil
    @State private var recorder: AudioRecorder? = nil
    @State private var isRecording = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Transcription Title", text: $entry.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                VStack(spacing: 16) {
                    Button {
                        Task {
                            if isRecording {
                                await stopRecording()
                            } else {
                                await startRecording()
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.title2)
                            Text(isRecording ? "Stop Recording" : "Start Recording")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(isRecording ? Color.red : Color.blue)
                        .cornerRadius(12)
                    }

                    if isRecording {
                        Text("Recording...")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                ScrollView {
                    VStack(alignment: .leading) {
                        if !entry.text.characters.isEmpty {
                            Text(entry.text)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("Your transcription will appear here...")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let transcriber = transcriber, !transcriber.volatileTranscript.characters.isEmpty {
                            Text(transcriber.volatileTranscript)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding()

                Spacer()
            }
            .navigationTitle("New Transcription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTranscription()
                    }
                    .disabled(entry.title.isEmpty || entry.text.characters.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func startRecording() async {
        do {
            transcriber = SpokenWordTranscriber(entry: $entry)
            recorder = AudioRecorder(transcriber: transcriber!, entry: $entry)

            try await recorder?.startRecording()
            isRecording = true
        } catch {
            alertMessage = "Failed to start recording: \(error.localizedDescription)"
            showingAlert = true
            isRecording = false
        }
    }

    private func stopRecording() async {
        do {
            try await recorder?.stopRecording()
            isRecording = false
        } catch {
            alertMessage = "Failed to stop recording: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func saveTranscription() {
        entry.isDone = true
        store.addTranscription(entry)
        dismiss()
    }
}