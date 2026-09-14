import Foundation

enum TripFormat {
    static func mediumDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func cityCode(_ city: String) -> String {
        let letters = city.uppercased().filter { character in
            character.isLetter
        }
        if letters.count >= 3 {
            return String(letters.prefix(3))
        }
        if letters.isEmpty {
            return "TRP"
        }
        let padCount = 3 - letters.count
        return letters + String(repeating: "X", count: padCount)
    }

    static func packedCount(done: Int, total: Int) -> String {
        if total == 0 {
            return "Empty case"
        }
        return "\(done)/\(total) packed"
    }

    static func dateRange(start: Date, end: Date) -> String {
        if Calendar.current.isDate(start, inSameDayAs: end) {
            return mediumDate(start)
        }
        return "\(mediumDate(start)) – \(mediumDate(end))"
    }

    static func countdown(start: Date, end: Date, now: Date = Date()) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        if today < startDay {
            let days = calendar.dateComponents([.day], from: today, to: startDay).day ?? 0
            if days == 0 {
                return "Departs today"
            }
            if days == 1 {
                return "1 day left"
            }
            return "\(days) days left"
        }
        if today <= endDay {
            let remaining = calendar.dateComponents([.day], from: today, to: endDay).day ?? 0
            if remaining == 0 {
                return "In town today"
            }
            if remaining == 1 {
                return "In town · 1 day left"
            }
            return "In town · \(remaining) days left"
        }
        return "Dates passed"
    }

    static func money(_ value: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(currency) \(value)"
    }

    static func amountString(_ value: Double) -> String {
        if value == 0 {
            return ""
        }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
    }

    static func amountValue(_ raw: String) -> Double {
        let cleaned = raw.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty {
            return 0
        }
        return Double(cleaned) ?? 0
    }
}
