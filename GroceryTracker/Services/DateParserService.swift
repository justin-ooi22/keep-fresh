import Foundation

/// Service dedicated to detecting, extracting, and parsing expiration dates from camera OCR text.
public final class DateParserService {
    public static let shared = DateParserService()
    
    private init() {}
    
    /// Month name dictionary mapping abbreviations and full names to month numbers (1-12)
    private let monthLookup: [String: Int] = [
        "jan": 1, "january": 1,
        "feb": 2, "february": 2,
        "mar": 3, "march": 3,
        "apr": 4, "april": 4,
        "may": 5,
        "jun": 6, "june": 6,
        "jul": 7, "july": 7,
        "aug": 8, "august": 8,
        "sep": 9, "sept": 9, "september": 9,
        "oct": 10, "october": 10,
        "nov": 11, "november": 11,
        "dec": 12, "december": 12
    ]
    
    /// Common expiration prefixes used on grocery packaging
    private let expiryKeywords = [
        "best before", "best by", "bb", "exp", "expiry", "expires", "use by", "b.b.", "exp.", "mfd", "valid"
    ]
    
    /// Parses a string of scanned text (or array of text lines) and returns the most probable expiration date.
    public func extractBestExpiryDate(from text: String) -> Date? {
        let lines = text.components(separatedBy: .newlines)
        
        var candidates: [(date: Date, confidence: Int)] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            let lower = trimmed.lowercased()
            let hasKeyword = expiryKeywords.contains { lower.contains($0) }
            let baseScore = hasKeyword ? 50 : 10
            
            if let date = parseDateString(trimmed) {
                // Ensure date is reasonable (e.g. within past 1 year to future 10 years)
                if isReasonableGroceryDate(date) {
                    candidates.append((date, baseScore + 20))
                }
            }
        }
        
        // Also run full regex over the entire text blob if line-by-line missed compound dates
        if candidates.isEmpty {
            for match in scanRegexPatterns(in: text) {
                if isReasonableGroceryDate(match) {
                    candidates.append((match, 15))
                }
            }
        }
        
        // Return candidate with highest confidence score
        return candidates.sorted { $0.confidence > $1.confidence }.first?.date
    }
    
    /// Validates date is within reasonable perishable grocery timeline
    private func isReasonableGroceryDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        guard let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now),
              let tenYearsFuture = calendar.date(byAdding: .year, value: 10, to: now) else {
            return false
        }
        return date >= oneYearAgo && date <= tenYearsFuture
    }
    
    /// Attempts various standard date formatters
    private func parseDateString(_ raw: String) -> Date? {
        // Strip common prefixes like "BB", "EXP", "BEST BY", colons, etc.
        var cleaned = raw
        for kw in expiryKeywords {
            let regex = try? NSRegularExpression(pattern: "(?i)\(kw)\\s*[:.-]?\\s*", options: [])
            if let regex = regex {
                cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count), withTemplate: "")
            }
        }
        cleaned = cleaned.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        
        let formats = [
            "dd/MM/yyyy", "dd-MM-yyyy", "dd.MM.yyyy",
            "yyyy-MM-dd", "yyyy/MM/dd",
            "MM/dd/yyyy", "MM-dd-yyyy",
            "dd/MM/yy", "dd-MM-yy", "dd.MM.yy",
            "MM/dd/yy", "MM.dd.yy",
            "dd MMM yyyy", "dd-MMM-yyyy", "dd MMM yy", "dd-MMM-yy",
            "MMM yyyy", "MM/yyyy", "MM/yy"
        ]
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: cleaned) {
                return date
            }
        }
        
        return nil
    }
    
    /// Regex scanning over entire block for common date patterns
    private func scanRegexPatterns(in text: String) -> [Date] {
        var foundDates: [Date] = []
        
        // Pattern 1: DD/MM/YYYY or DD.MM.YY or YYYY-MM-DD
        let numericPattern = #"\b(\d{1,2})[\/.-](\d{1,2})[\/.-](\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: numericPattern) {
            let nsString = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
            for match in matches {
                let matchString = nsString.substring(with: match.range)
                if let date = parseDateString(matchString) {
                    foundDates.append(date)
                }
            }
        }
        
        // Pattern 2: DD MON YYYY (e.g. 15 OCT 26 or 15-OCT-2026)
        let alphaPattern = #"\b(\d{1,2})[\s\/-]?([A-Za-z]{3,9})[\s\/-]?(\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: alphaPattern) {
            let nsString = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
            for match in matches {
                let matchString = nsString.substring(with: match.range)
                if let date = parseDateString(matchString) {
                    foundDates.append(date)
                }
            }
        }
        
        return foundDates
    }
}
