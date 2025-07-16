import 'package:flutter/material.dart';
import 'package:real_estate/models/book_manager.dart';
import 'package:real_estate/models/property_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Recent';

  List sortBookmarks(List bookmarks) {
    List sorted = List.of(bookmarks);
    switch (_sortBy) {
      case 'Price Low':
        sorted.sort(
          (a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)),
        );
        break;
      case 'Price High':
        sorted.sort(
          (a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)),
        );
        break;
      case 'Name':
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case 'Recent':
      default:
        // No sorting or keep as is
        break;
    }
    return sorted;
  }

  int _parsePrice(String price) {
    final cleaned = price.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: BookmarkManager().bookmarkCount,
        builder: (context, count, _) {
          final allBookmarks = BookmarkManager().bookmarkedProperties;
          final filtered = allBookmarks.where((p) {
            final q = _searchQuery.toLowerCase();
            return p.title.toLowerCase().contains(q) ||
                p.location.toLowerCase().contains(q);
          }).toList();
          final bookmarks = sortBookmarks(filtered);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search bookmarked properties...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (bookmarks.isEmpty)
                const Expanded(child: Center(child: Text('No bookmarks yet.')))
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final property = bookmarks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: PropertyCard(
                          property: property,
                          onTap: () {
                            // Optionally navigate to property details
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort Bookmarks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('Recently Added'),
                onTap: () {
                  setState(() => _sortBy = 'Recent');
                  Navigator.pop(context);
                },
                selected: _sortBy == 'Recent',
              ),
              ListTile(
                title: const Text('Price: Low to High'),
                onTap: () {
                  setState(() => _sortBy = 'Price Low');
                  Navigator.pop(context);
                },
                selected: _sortBy == 'Price Low',
              ),
              ListTile(
                title: const Text('Price: High to Low'),
                onTap: () {
                  setState(() => _sortBy = 'Price High');
                  Navigator.pop(context);
                },
                selected: _sortBy == 'Price High',
              ),
              ListTile(
                title: const Text('Name A-Z'),
                onTap: () {
                  setState(() => _sortBy = 'Name');
                  Navigator.pop(context);
                },
                selected: _sortBy == 'Name',
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
