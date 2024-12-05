import Foundation

func formatDate(date: Date?) -> String {
    guard let d = date else {
        return Date().formatted(
            date: .abbreviated,
            time: .shortened
        )
    }

    let displayFormatter = DateFormatter()
    displayFormatter.dateStyle = .medium
    displayFormatter.timeStyle = .short
    displayFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Keep original timezone

    return displayFormatter.string(from: d)
}
