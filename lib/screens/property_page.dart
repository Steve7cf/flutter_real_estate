import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:real_estate/models/property.dart';
import 'dart:io';
import 'package:real_estate/screens/property_chat_screen.dart';

class PropertyPage extends StatelessWidget {
  final Property property;

  const PropertyPage({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String postedDate = property.scrapedAt.isNotEmpty
        ? property.scrapedAt.split('T').first
        : '';
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  property.images.isNotEmpty
                      ? ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: property.images.length,
                          itemBuilder: (context, index) {
                            final img = property.images[index];
                            if (img.startsWith('/') ||
                                img.startsWith('file://')) {
                              return SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: Image.file(
                                  File(img),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 100),
                                ),
                              );
                            } else {
                              return SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: CachedNetworkImage(
                                  imageUrl: img,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error, size: 100),
                                ),
                              );
                            }
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          height: 320,
                          width: double.infinity,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 100,
                          ),
                        ),
                  Positioned(
                    bottom: 20,
                    left: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(128),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                "4.9",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(128),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            property.type != 'N/A' ? property.type : 'Property',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            ),
            actions: [
              // Removed like and upload icons
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.price.startsWith('Tsh')
                        ? property.price
                        : 'Tsh ${property.price}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 20,
                        color: Colors.deepOrangeAccent,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Property Description",
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(property.description, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.king_bed_outlined),
                      const SizedBox(width: 4),
                      Text(property.bedrooms),
                      const SizedBox(width: 16),
                      const Icon(Icons.bathtub),
                      const SizedBox(width: 4),
                      Text(property.bathrooms),
                      const SizedBox(width: 16),
                      const Icon(Icons.square_foot),
                      const SizedBox(width: 4),
                      Text(property.area),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.category),
                      const SizedBox(width: 4),
                      Text(property.type),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        postedDate.isNotEmpty ? 'Posted on $postedDate' : '',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 340,
        height: 60,
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PropertyChatScreen(property: property),
              ),
            );
          },
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          label: const Text('Send Message', style: TextStyle(fontSize: 18)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
