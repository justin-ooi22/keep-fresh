import Foundation

/// Service dedicated to detecting, extracting, and parsing expiration dates from camera OCR text.
/// Fully supports European date formats (DD.MM.YYYY, DD.MM.YY) and German/multilingual packaging phrasing.
public final class DateParserService {
    public static let shared = DateParserService()
    
    private init() {}
    
    /// Month name dictionary mapping German, English, and common abbreviations to month numbers (1-12)
    private let monthLookup: [String: Int] = [
        // German
        "jan": 1, "januar": 1,
        "feb": 2, "februar": 2,
        "mär": 3, "maerz": 3, "märz": 3, "mar": 3,
        "apr": 4, "april": 4,
        "mai": 5,
        "jun": 6, "juni": 6,
        "jul": 7, "juli": 7,
        "aug": 8, "august": 8,
        "sep": 9, "sept": 9, "september": 9,
        "okt": 10, "oktober": 10,
        "nov": 11, "november": 11,
        "dez": 12, "dezember": 12,
        
        // English
        "january": 1,
        "february": 2,
        "march": 3,
        "may": 5,
        "june": 6,
        "july": 7,
        "oct": 10, "october": 10,
        "dec": 12, "december": 12
    ]
    
    /// Common expiration prefixes used on grocery packaging across Europe and North America
    private let expiryKeywords: [String] = [
        // German phrases
        "mindestens haltbar bis ende",
        "mindestens haltbar bis",
        "mindestens haltbar",
        "zu verbrauchen bis",
        "verbrauchsdatum",
        "verfalldatum",
        "haltbar bis",
        "abgelaufen am",
        "mhd",
        
        // English phrases
        "best before end",
        "best before",
        "best by",
        "use by",
        "bb",
        "b.b.",
        "exp",
        "exp.",
        "expiry",
        "expires",
        "valid until",
        "valid to",
        
        // French & other European
        "a consommer jusqu'au",
        "a consommer de preference avant",
        "da consumarsi entro"
    ]
    
    /// Parses scanned text (single string or multi-line block) and returns the most probable expiration date.
    public func extractBestExpiryDate(from text: String) -> Date? {
        let lines = text.components(separatedBy: .newlines)
        var candidates: [(date: Date, confidence: Int)] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            let lower = trimmed.lowercased()
            let hasKeyword = expiryKeywords.contains { lower.contains($0) }
            let baseScore = hasKeyword ? 70 : 15
            
            // 1. Scan line for dates
            let lineDates = extractDatesFromLine(trimmed)
            for date in lineDates {
                if isReasonableGroceryDate(date) {
                    candidates.append((date, baseScore + 20))
                }
            }
        }
        
        // 2. If line-by-line yielded nothing (e.g. "Mindestens haltbar bis:" on line 1, "24.11.2026" on line 2),
        // scan across the normalized full text block
        if candidates.isEmpty {
            let fullDates = extractDatesFromLine(text.replacingOccurrences(of: "\n", with: " "))
            for date in fullDates {
                if isReasonableGroceryDate(date) {
                    candidates.append((date, 20))
                }
            }
        }
        
        // Return candidate with highest confidence
        return candidates.sorted { $0.confidence > $1.confidence }.first?.date
    }
    
    /// Extracts all valid date matches from a given string
    private func extractDatesFromLine(_ raw: String) -> [Date] {
        var foundDates: [Date] = []
        let calendar = Calendar.current
        
        // Clean up common OCR spacing around dots: e.g. "24 . 11 . 2026" -> "24.11.2026"
        let normalized = raw.replacingOccurrences(of: #"\s*([.\/-])\s*"#, with: "$1", options: .regularExpression)
        
        // Pattern 1: European Numeric DD.MM.YYYY, DD/MM/YYYY, DD-MM-YYYY or DD.MM.YY
        // Examples: 24.11.2026, 07.09.26, 15/10/2026, 01-12-25
        let euroNumericRegex = #"\b(\d{1,2})[.\/-](\d{1,2})[.\/-](\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: euroNumericRegex) {
            let nsString = normalized as NSString
            let matches = regex.matches(in: normalized, range: NSRange(location: 0, length: normalized.utf16.count))
            for match in matches where match.numberOfRanges == 4 {
                let dayStr = nsString.substring(with: match.range(at: 1))
                let monthStr = nsString.substring(with: match.range(at: 2))
                let yearStr = nsString.substring(with: match.range(at: 3))
                
                if let day = Int(dayStr), let month = Int(monthStr), let rawYear = Int(yearStr) {
                    let year = rawYear < 100 ? (2000 + rawYear) : rawYear
                    
                    // In Europe, day comes first (DD.MM.YYYY)
                    if (1...31).contains(day) && (1...12).contains(month) {
                        var comp = DateComponents()
                        comp.year = year
                        comp.month = month
                        comp.day = day
                        comp.hour = 12
                        if let date = calendar.date(from: comp) {
                            foundDates.append(date)
                        }
                    }
                }
            }
        }
        
        // Pattern 2: Alphanumeric DD. MMM. YYYY or DD MMM YYYY (German & English)
        // Examples: 15. Okt. 2026, 15. Oktober 2026, 12 März 2026, 05-Dez-26, 20 OCT 2026
        let alphaRegex = #"\b(\d{1,2})\.?[-\s]([A-Za-zäöüÄÖÜ]{3,10})\.?[-\s](\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: alphaRegex) {
            let nsString = normalized as NSString
            let matches = regex.matches(in: normalized, range: NSRange(location: 0, length: normalized.utf16.count))
            for match in matches where match.numberOfRanges == 4 {
                let dayStr = nsString.substring(with: match.range(at: 1))
                let monthWord = nsString.substring(with: match.range(at: 2)).lowercased()
                let yearStr = nsString.substring(with: match.range(at: 3))
                
                if let day = Int(dayStr),
                   let month = monthLookup[monthWord] ?? monthLookup[String(monthWord.prefix(3))],
                   let rawYear = Int(yearStr) {
                    let year = rawYear < 100 ? (2000 + rawYear) : rawYear
                    if (1...31).contains(day) {
                        var comp = DateComponents()
                        comp.year = year
                        comp.month = month
                        comp.day = day
                        comp.hour = 12
                        if let date = calendar.date(from: comp) {
                            foundDates.append(date)
                        }
                    }
                }
            }
        }
        
        // Pattern 3: Month & Year only (e.g., canned foods, "Mindestens haltbar bis Ende 11.2026" or "10/2027")
        // Examples: 11.2026, 11/2026, 08.26
        let monthYearRegex = #"(?:ende|end)?\s*[:.-]?\s*\b(\d{1,2})[.\/-](\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: monthYearRegex, options: .caseInsensitive) {
            let nsString = normalized as NSString
            let matches = regex.matches(in: normalized, range: NSRange(location: 0, length: normalized.utf16.count))
            for match in matches where match.numberOfRanges == 3 {
                let monthStr = nsString.substring(with: match.range(at: 1))
                let yearStr = nsString.substring(with: match.range(at: 2))
                
                if let month = Int(monthStr), let rawYear = Int(yearStr) {
                    let year = rawYear < 100 ? (2000 + rawYear) : rawYear
                    if (1...12).contains(month) && year >= 2024 && year <= 2040 {
                        // Set to last day of that month
                        var comp = DateComponents()
                        comp.year = year
                        comp.month = month
                        comp.day = 1
                        comp.hour = 12
                        if let firstDay = calendar.date(from: comp),
                           let range = calendar.range(of: .day, in: .month, for: firstDay) {
                            comp.day = range.count
                            if let endOfMonthDate = calendar.date(from: comp) {
                                foundDates.append(endOfMonthDate)
                            }
                        }
                    }
                }
            }
        }
        
        return foundDates
    }
    
    /// Validates date is within reasonable perishable grocery timeline (past 1 year to future 10 years)
    private func isReasonableGroceryDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        guard let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now),
              let tenYearsFuture = calendar.date(byAdding: .year, value: 10, to: now) else {
            return false
        }
        return date >= oneYearAgo && date <= tenYearsFuture
    }
}
