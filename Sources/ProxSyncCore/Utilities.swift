import Foundation

public enum JSONCoding {
    public static func iso8601String(from date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: date)
    }

    public static func dateFromISO8601(_ string: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: string)
    }
}


public enum Backoff {
    public static func delay(for attempt: Int) -> TimeInterval {
        let capped = min(attempt, 6)
        return pow(2.0, Double(capped)) // 2,4,8,16,32,64
    }
}
