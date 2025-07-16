import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:real_estate/models/property.dart';

class PropertyService {
  static Future<List<Property>> loadProperties() async {
    try {
      final response = await http
          .get(Uri.parse('https://your-api.com/properties'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load properties: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading properties: $e');
    }
  }

  static Future<List<Property>> loadMockProperties() async {
    await Future.delayed(const Duration(seconds: 1));
    try {
      const mockJson = '''
      [
        {
          "title": "Property",
          "price": "TZS 500,000,000",
          "location": "Unknown Location",
          "description": "No description available",
          "bedrooms": "N/A",
          "bathrooms": "N/A",
          "area": "N/A",
          "type": "N/A",
          "url": "https://real-estate-tanzania.beforward.jp/property/",
          "scraped_at": "2025-06-13T02:53:52.362406",
          "images": "https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/IMG-20250613-WA0106-592x444.jpg, https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/1000158498-592x369.jpg"
        },
        {
          "title": "House for Rent at Mbezi Beach",
          "price": "TZS 1,200,000",
          "location": "Mbezi Beach",
          "description": "No description available",
          "bedrooms": "N/A",
          "bathrooms": "N/A",
          "area": "N/A",
          "type": "House",
          "url": "https://real-estate-tanzania.beforward.jp/property/house-for-rent-at-mbezi-beach-7/",
          "scraped_at": "2025-06-13T02:53:56.649663",
          "images": "https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/IMG-20250613-WA01002-592x444.jpg, https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/1000232691-592x444.jpg"
        },
        {
          "title": "3 Bedrooms House Ununio",
          "price": "TZS 800,000,000",
          "location": "Ununio",
          "description": "No description available",
          "bedrooms": "3",
          "bathrooms": "N/A",
          "area": "N/A",
          "type": "House",
          "url": "https://real-estate-tanzania.beforward.jp/property/3-bedrooms-house-ununio/",
          "scraped_at": "2025-06-13T02:54:03.972364",
          "images": "https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/1000232691-592x444.jpg, https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/IMG-20250613-WA0106-592x444.jpg"
        },
        {
          "title": "Villa for Sale Bahari Beach",
          "price": "TZS 1,500,000,000",
          "location": "Bahari Beach",
          "description": "No description available",
          "bedrooms": "N/A",
          "bathrooms": "N/A",
          "area": "N/A",
          "type": "Villa",
          "url": "https://real-estate-tanzania.beforward.jp/property/villa-for-sale-bahar-beach/",
          "scraped_at": "2025-06-13T02:56:02.835557",
          "images": "https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/1000048008-592x444.jpg, https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/1000232630-592x444.jpg"
        },
        {
          "title": "Apartment for Sale Kinondoni",
          "price": "TZS 600,000,000",
          "location": "Kinondoni",
          "description": "No description available",
          "bedrooms": "N/A",
          "bathrooms": "N/A",
          "area": "N/A",
          "type": "Apartment",
          "url": "https://real-estate-tanzania.beforward.jp/property/apartment-for-sale-kinondoni/",
          "scraped_at": "2025-06-13T02:56:10.123456",
          "images": "https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/1000158498-592x369.jpg, https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/IMG-20250613-WA01002-592x444.jpg"
        },
        {
          "title": "Plot for Sale Mbezi",
          "price": "Offers are invited",
          "location": "Mbezi",
          "description": "No description available",
          "bedrooms": "N/A",
          "bathrooms": "N/A",
          "area": "N/A",
          "type": "Plot",
          "url": "https://real-estate-tanzania.beforward.jp/property/plot-for-sale-mbezi/",
          "scraped_at": "2025-06-13T02:56:15.789012",
          "images": "https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/1000232630-592x444.jpg, https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/1000048008-592x444.jpg"
        },
        {
          "title": "House for Sale Goba",
          "price": "TZS 900,000,000",
          "location": "Goba",
          "description": "No description available",
          "bedrooms": "N/A",
          "bathrooms": "N/A",
          "area": "N/A",
          "type": "House",
          "url": "https://real-estate-tanzania.beforward.jp/property/house-for-sale-goba/",
          "scraped_at": "2025-06-13T02:56:20.345678",
          "images": "https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/IMG-20250613-WA0106-592x444.jpg, https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/1000232691-592x444.jpg"
        },
        {
          "title": "Condo for Rent Mikocheni",
          "price": "TZS 2,000,000",
          "location": "Mikocheni",
          "description": "No description available",
          "bedrooms": "N/A",
          "bathrooms": "N/A",
          "area": "N/A",
          "type": "Condo",
          "url": "https://real-estate-tanzania.beforward.jp/property/condo-for-rent-mikocheni/",
          "scraped_at": "2025-06-13T02:56:25.901234",
          "images": "https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/1000158498-592x369.jpg, https://real-estate-tanzania.beforward.jp/wp-content/uploads/2025/06/1000048008-592x444.jpg"
        }
      ]
      ''';
      final List<dynamic> data = jsonDecode(mockJson);
      final properties = data.map((json) => Property.fromJson(json)).toList();
      return properties;
    } catch (e) {
      return [];
    }
  }
}
