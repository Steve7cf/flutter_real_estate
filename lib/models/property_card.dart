import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:real_estate/models/book_manager.dart';
import 'package:real_estate/models/property.dart';
import 'dart:io';
import 'package:real_estate/screens/property_page.dart';
import 'package:real_estate/screens/property_chat_screen.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const PropertyCard({super.key, required this.property, this.onTap});

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('/') || imagePath.startsWith('file://')) {
      // Local file
      return Image.file(
        File(imagePath),
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 50),
      );
    } else {
      // Network image
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(Icons.error, size: 50),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: property.images.isNotEmpty
                      ? _buildImage(property.images.first)
                      : Container(
                          width: double.infinity,
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                          ),
                        ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xff48e256),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Active",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(
                        102,
                      ), // Changed from .withOpacity(0.4)
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      property.price.startsWith('Tsh')
                          ? property.price
                          : 'Tsh ${property.price}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 17,
                            color: isDark ? Colors.white : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: BookmarkManager().bookmarkCount,
                        builder: (context, _, __) {
                          final isBookmarked = BookmarkManager().isBookmarked(
                            property,
                          );
                          return IconButton(
                            icon: Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_outline,
                              color: isBookmarked
                                  ? const Color(0xff48e256)
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              BookmarkManager().toggleBookmark(property);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isBookmarked
                                        ? 'Removed from bookmarks'
                                        : 'Added to bookmarks',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.deepOrangeAccent,
                        size: 18,
                      ),
                      Expanded(
                        child: Text(
                          property.location,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.king_bed_outlined),
                      const SizedBox(width: 4),
                      Text(
                        property.bedrooms,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.bathtub),
                      const SizedBox(width: 4),
                      Text(
                        property.bathrooms,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              onTap ??
                              () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PropertyPage(property: property),
                                  ),
                                );
                              },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('View Details'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    PropertyChatScreen(property: property),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primaryColor,
                            side: BorderSide(color: theme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Send Message'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
