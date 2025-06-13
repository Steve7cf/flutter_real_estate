
class Property {
  final String id;
  final String title;
  final String price;
  final String location;
  final String description;
  final String bedrooms;
  final String bathrooms;
  final String area;
  final String type;
  final String url;
  final String scrapedAt;
  final List<String> images;

  Property({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.description,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.type,
    required this.url,
    required this.scrapedAt,
    required this.images,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['images'] as String? ?? '';
    final id = json['id'] as String? ??
        json['documentId'] as String? ??
        '${(json['title'] ?? '').hashCode}${json['location'] ?? ''}${json['url'] ?? ''}'.hashCode.toString();
    return Property(
      id: id,
      title: json['title'] as String? ?? 'Property',
      price: json['price'] as String? ?? 'N/A',
      location: json['location'] as String? ?? 'Unknown Location',
      description: json['description'] as String? ?? 'No description available',
      bedrooms: json['bedrooms'] as String? ?? 'N/A',
      bathrooms: json['bathrooms'] as String? ?? 'N/A',
      area: json['area'] as String? ?? 'N/A',
      type: json['type'] as String? ?? 'N/A',
      url: json['url'] as String? ?? '',
      scrapedAt: json['scraped_at'] as String? ?? '',
      images: imagesRaw.isNotEmpty ? imagesRaw.split(', ').map((e) => e.trim()).toList() : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'location': location,
      'description': description,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'type': type,
      'url': url,
      'scraped_at': scrapedAt,
      'images': images.join(', '),
    };
  }
}
