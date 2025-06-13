import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:real_estate/models/book_manager.dart';
import 'package:real_estate/models/property.dart';
import 'package:url_launcher/url_launcher.dart';


class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const PropertyCard({super.key, required this.property, this.onTap});

  Future<void> _launchUrl(BuildContext context) async {
    try {
      String urlToLaunch = property.url;
      if (urlToLaunch.isEmpty) {
        throw Exception('No URL provided');
      }
      if (!urlToLaunch.startsWith('http://') && !urlToLaunch.startsWith('https://')) {
        urlToLaunch = 'https://$urlToLaunch';
      }
      final uri = Uri.parse(urlToLaunch);
      print('Attempting to launch URL: $urlToLaunch');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot launch URL');
      }
    } catch (e) {
      print('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open link: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
                      ? CachedNetworkImage(
                          imageUrl: property.images.first,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error, size: 50),
                        )
                      : Container(
                          width: double.infinity,
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, size: 50),
                        ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  top: 10,
                  right: 10,
                  child: IconButton(
                    onPressed: () => _launchUrl(context),
                    icon: const Icon(Icons.link_outlined),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffc6c8f3),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      property.price,
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
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: BookmarkManager().bookmarkCount,
                        builder: (context, _, __) {
                          final isBookmarked = BookmarkManager().isBookmarked(property);
                          return IconButton(
                            icon: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                              color: isBookmarked ? const Color(0xff48e256) : Colors.grey,
                            ),
                            onPressed: () {
                              BookmarkManager().toggleBookmark(property);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isBookmarked ? 'Removed from bookmarks' : 'Added to bookmarks',
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
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
                      Text(property.bedrooms),
                      const SizedBox(width: 16),
                      const Icon(Icons.bathtub),
                      const SizedBox(width: 4),
                      Text(property.bathrooms),
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
