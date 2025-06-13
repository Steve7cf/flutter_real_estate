
import 'package:flutter/foundation.dart';
import 'package:real_estate/models/property.dart';

class BookmarkManager {
  static final BookmarkManager _instance = BookmarkManager._internal();
  factory BookmarkManager() => _instance;
  BookmarkManager._internal();

  final List<Property> _bookmarkedProperties = [];
  final ValueNotifier<int> _bookmarkCount = ValueNotifier(0);

  List<Property> get bookmarkedProperties => List.unmodifiable(_bookmarkedProperties);
  ValueNotifier<int> get bookmarkCount => _bookmarkCount;

  bool isBookmarked(Property property) => _bookmarkedProperties.any((p) => p.id == property.id);

  void toggleBookmark(Property property) {
    if (isBookmarked(property)) {
      _bookmarkedProperties.removeWhere((p) => p.id == property.id);
    } else {
      _bookmarkedProperties.add(property);
    }
    _bookmarkCount.value = _bookmarkedProperties.length;
  }
}