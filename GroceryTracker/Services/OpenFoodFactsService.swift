import Foundation

/// Product information fetched from barcode lookup
public struct ProductLookupResult {
    public let barcode: String
    public let name: String
    public let brand: String
    public let imageUrl: URL?
    public let suggestedCategory: ItemCategory
}

/// Service for looking up grocery product details using Open Food Facts API
public final class OpenFoodFactsService {
    public static let shared = OpenFoodFactsService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 6.0
        // Set respectful user agent as requested by Open Food Facts API guidelines
        config.httpAdditionalHeaders = [
            "User-Agent": "FreshKeep-GroceryTracker - iOS - Version 1.0"
        ]
        self.session = URLSession(configuration: config)
    }
    
    /// Looks up a product by barcode (EAN-13, UPC-A, etc.)
    public func lookupProduct(barcode: String) async -> ProductLookupResult? {
        let trimmed = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(trimmed).json") else {
            return nil
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let status = json?["status"] as? Int, status == 1,
                  let product = json?["product"] as? [String: Any] else {
                return nil
            }
            
            // Extract product name with fallbacks
            let name = (product["product_name"] as? String)?.trimmingCharacters(in: .whitespaces)
                ?? (product["product_name_en"] as? String)?.trimmingCharacters(in: .whitespaces)
                ?? "Unknown Product"
            
            let brand = (product["brands"] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
            
            var imageUrl: URL? = nil
            if let imageString = product["image_front_url"] as? String ?? product["image_url"] as? String {
                imageUrl = URL(string: imageString)
            }
            
            let categoriesTags = (product["categories_tags"] as? [String]) ?? []
            let categoriesString = (product["categories"] as? String) ?? ""
            let suggestedCategory = guessCategory(name: name, tags: categoriesTags, categoriesString: categoriesString)
            
            return ProductLookupResult(
                barcode: trimmed,
                name: name,
                brand: brand,
                imageUrl: imageUrl,
                suggestedCategory: suggestedCategory
            )
        } catch {
            return nil
        }
    }
    
    /// Guesses the appropriate ItemCategory based on product taxonomy tags and name
    private func guessCategory(name: String, tags: [String], categoriesString: String) -> ItemCategory {
        let text = "\(name) \(tags.joined(separator: " ")) \(categoriesString)".lowercased()
        
        if text.contains("dairy") || text.contains("milk") || text.contains("cheese") || text.contains("yogurt") || text.contains("butter") || text.contains("egg") {
            return .dairy
        }
        if text.contains("fruit") || text.contains("vegetable") || text.contains("apple") || text.contains("salad") || text.contains("banana") || text.contains("tomato") {
            return .produce
        }
        if text.contains("meat") || text.contains("beef") || text.contains("chicken") || text.contains("pork") || text.contains("fish") || text.contains("salmon") || text.contains("seafood") {
            return .meat
        }
        if text.contains("bread") || text.contains("bakery") || text.contains("croissant") || text.contains("bagel") || text.contains("cake") || text.contains("toast") {
            return .bakery
        }
        if text.contains("frozen") || text.contains("ice cream") || text.contains("pizza") {
            return .frozen
        }
        if text.contains("beverage") || text.contains("drink") || text.contains("juice") || text.contains("coffee") || text.contains("tea") || text.contains("soda") || text.contains("water") {
            return .beverages
        }
        if text.contains("sauce") || text.contains("condiment") || text.contains("ketchup") || text.contains("mayo") || text.contains("dressing") || text.contains("oil") {
            return .condiments
        }
        if text.contains("snack") || text.contains("chip") || text.contains("cookie") || text.contains("chocolate") || text.contains("candy") {
            return .snacks
        }
        if text.contains("canned") || text.contains("pasta") || text.contains("rice") || text.contains("cereal") || text.contains("flour") || text.contains("soup") {
            return .pantry
        }
        
        return .other
    }
}
