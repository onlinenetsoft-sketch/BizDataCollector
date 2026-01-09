import Foundation

struct BusinessListing: Identifiable, Codable {
    let id = UUID()
    let name: String
    let category: String
    let address: String
    let city: String
    let province: String
    let postalCode: String
    let phone: String
    let url: String?
    let latitude: Double?
    let longitude: Double?
    
    var fullAddress: String {
        "\(address), \(city), \(province) \(postalCode)"
    }
    
    // Excel/CSV column mapping
    var csvRow: [String] {
        [name, category, address, city, province, postalCode, phone, url ?? ""]
    }
    
    static var csvHeaders: [String] {
        ["Name", "Category", "Address", "City", "Province", "PostalCode", "Phone", "URL"]
    }
}