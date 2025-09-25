import Foundation
import AVFoundation
import FoundationModels

@Observable
class TranscriptionEntry: Identifiable, Codable {
    let id: UUID
    var title: String
    var date: Date
    var text: AttributedString
    var url: URL?
    var isDone: Bool

    init(title: String, text: AttributedString = AttributedString(""), url: URL? = nil, isDone: Bool = false) {
        self.id = UUID()
        self.title = title
        self.date = Date()
        self.text = text
        self.url = url
        self.isDone = isDone
    }

    enum CodingKeys: CodingKey {
        case id, title, date, text, url, isDone
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)

        if let textData = try container.decodeIfPresent(Data.self, forKey: .text) {
            if let nsAttrString = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: textData) {
                text = AttributedString(nsAttrString)
            } else {
                text = AttributedString("")
            }
        } else {
            text = AttributedString("")
        }

        url = try container.decodeIfPresent(URL.self, forKey: .url)
        isDone = try container.decodeIfPresent(Bool.self, forKey: .isDone) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)

        let nsAttrString = NSAttributedString(text)
        let textData = try NSKeyedArchiver.archivedData(withRootObject: nsAttrString, requiringSecureCoding: true)
        try container.encode(textData, forKey: .text)

        try container.encodeIfPresent(url, forKey: .url)
        try container.encode(isDone, forKey: .isDone)
    }

    func suggestedTitle() async throws -> String? {
        guard SystemLanguageModel.default.isAvailable else { return nil }
        let session = LanguageModelSession(model: SystemLanguageModel.default)
        let answer = try await session.respond(to: "Here is a transcription. Can you please return your very best suggested title for it, with no other text? The title should be descriptive. Transcription: \(text.characters)")
        return answer.content.trimmingCharacters(in: .punctuationCharacters)
    }
}

extension TranscriptionEntry {
    static func blank() -> TranscriptionEntry {
        return .init(title: "New Transcription", text: AttributedString(""))
    }

    var hasAudioFile: Bool {
        guard let url = url else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    var audioDuration: TimeInterval? {
        guard hasAudioFile, let url = url else { return nil }

        do {
            let audioFile = try AVAudioFile(forReading: url)
            let sampleRate = audioFile.processingFormat.sampleRate
            let length = audioFile.length
            return Double(length) / sampleRate
        } catch {
            return nil
        }
    }

    func deleteAudioFile() {
        guard let url = url, hasAudioFile else { return }

        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Failed to delete audio file: \(error)")
        }
    }
}