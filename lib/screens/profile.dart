// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:real_estate/auth/auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:real_estate/models/property.dart';
import 'package:real_estate/models/book_manager.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

// Profile Menu Item Widget
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showArrow;
  final Color? iconColor;
  final Widget? trailing;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.showArrow = true,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFF2E7D32)).withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ?? const Color(0xFF2E7D32),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              )
            : null,
        trailing:
            trailing ??
            (showArrow
                ? const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  )
                : null),
        onTap: onTap,
      ),
    );
  }
}

// Profile Stats Widget
class ProfileStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const ProfileStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Main Profile Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.darkModeNotifier});
  final ValueNotifier<bool> darkModeNotifier;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _isLoading = false;
  List<Property> userListings = [];
  int bookmarkCount = 0;
  List<Map<String, dynamic>> boughtProperties = [];

  // Get current user info
  User? get currentUser => authService.value.currentUser;

  // Helper method to get display name
  String get displayName {
    if (currentUser?.displayName != null &&
        currentUser!.displayName!.isNotEmpty) {
      return currentUser!.displayName!;
    }
    // Fallback: use email prefix or "User"
    if (currentUser?.email != null) {
      return currentUser!.email!.split('@')[0];
    }
    return 'User';
  }

  // Helper method to get user email
  String get userEmail {
    return currentUser?.email ?? 'No email available';
  }

  // Helper method to get user photo URL
  String? get userPhotoURL {
    return currentUser?.photoURL;
  }

  // Helper method to check if email is verified
  bool get isEmailVerified {
    return currentUser?.emailVerified ?? false;
  }

  // Helper method to get membership status
  String get membershipStatus {
    // You can implement your own logic here
    // For now, we'll check if email is verified
    if (isEmailVerified) {
      return 'Verified Member';
    }
    return 'Basic Member';
  }

  @override
  void initState() {
    super.initState();
    _loadUserListings();
    _loadBookmarkCount();
    _loadNotificationPref();
    _loadBoughtProperties();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBoughtProperties();
    _loadUserListings();
  }

  Future<void> _loadUserListings() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('user_listings') ?? [];
    bool needsMigration = false;
    final updatedList = list.map((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      // Ensure id is never empty
      String id = (map['id'] ?? '').toString();
      if (id.isEmpty) {
        // Fallback: hash of title+location+scraped_at
        final title = map['title'] ?? '';
        final location = map['location'] ?? '';
        final scrapedAt = map['scraped_at'] ?? '';
        id = '${title}_${location}_$scrapedAt'.hashCode.toString();
        map['id'] = id;
        needsMigration = true;
      }
      return jsonEncode(map);
    }).toList();
    if (needsMigration) {
      await prefs.setStringList('user_listings', updatedList);
    }
    setState(() {
      userListings = updatedList.map((e) {
        final map = jsonDecode(e) as Map<String, dynamic>;
        return Property(
          id: map['id'] ?? '',
          title: map['title'] ?? '',
          price: map['price'] ?? '',
          location: map['location'] ?? '',
          description: map['description'] ?? '',
          bedrooms: map['bedrooms'] ?? '',
          bathrooms: map['bathrooms'] ?? '',
          area: map['area'] ?? '',
          type: map['type'] ?? '',
          url: map['url'] ?? '',
          scrapedAt: map['scraped_at'] ?? '',
          images: (map['images'] is List)
              ? List<String>.from(map['images'])
              : (map['imagePath'] != null ? [map['imagePath']] : []),
        );
      }).toList();
    });
  }

  Future<void> _loadBoughtProperties() async {
    final prefs = await SharedPreferences.getInstance();
    final boughtList = prefs.getStringList('bought_properties') ?? [];
    setState(() {
      boughtProperties = boughtList
          .map((e) {
            try {
              return Map<String, dynamic>.from(jsonDecode(e));
            } catch (_) {
              return <String, dynamic>{};
            }
          })
          .where((e) => e.isNotEmpty)
          .toList();
    });
  }

  void _loadBookmarkCount() {
    setState(() {
      bookmarkCount = BookmarkManager().bookmarkedProperties.length;
    });
    BookmarkManager().bookmarkCount.addListener(() {
      setState(() {
        bookmarkCount = BookmarkManager().bookmarkedProperties.length;
      });
    });
  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('push_notifications_enabled');
    setState(() {
      _notificationsEnabled = enabled ?? true;
    });
    if (_notificationsEnabled) {
      await _enablePushNotifications();
    } else {
      await _disablePushNotifications();
    }
  }

  Future<void> _onNotificationToggle(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', value);
    if (value) {
      await _enablePushNotifications();
    } else {
      await _disablePushNotifications();
    }
  }

  Future<void> _enablePushNotifications() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      await FirebaseMessaging.instance.subscribeToTopic('all');
      await FirebaseMessaging.instance.getToken().then((token) {});
    } catch (e) {
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enabling push notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disablePushNotifications() async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('all');
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disabling push notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteListing(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('user_listings') ?? [];
    list.removeWhere((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map['id'] == id;
    });
    await prefs.setStringList('user_listings', list);
    await _loadUserListings();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listing deleted'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _editListing(Property property) async {
    // Navigate to edit listing screen (to be implemented)
    final updated = await Navigator.pushNamed(
      context,
      '/editListing',
      arguments: property,
    );
    if (updated == true) {
      await _loadUserListings();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if user is null
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xff35573B),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      _showMoreOptions(context);
                    },
                  ),
                ],
              ),
            ),

            // Profile Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  // Profile Image
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundImage: userPhotoURL != null
                              ? NetworkImage(userPhotoURL!)
                              : null,
                          backgroundColor: const Color(0xFF2E7D32),
                          child: userPhotoURL == null
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Name and Email
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.white.withAlpha(204),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (!isEmailVerified) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _sendEmailVerification(),
                          child: Icon(
                            Icons.warning,
                            color: Colors.orange.withAlpha(76),
                            size: 20,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isEmailVerified
                          ? Colors.green.withAlpha(51)
                          : Colors.orange.withAlpha(51),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      membershipStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Email verification warning
                  if (!isEmailVerified) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _sendEmailVerification(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(51),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.orange.withAlpha(128),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mail_outline,
                              color: Colors.orange.withAlpha(25),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Verify Email',
                              style: TextStyle(
                                color: Colors.orange.withAlpha(25),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 24, bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ProfileStatsCard(
                                title: 'Your\nListings',
                                value: userListings.length.toString(),
                                icon: Icons.home_work_outlined,
                                color: const Color(0xFF2196F3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ProfileStatsCard(
                                title: 'Bookmarked',
                                value: bookmarkCount.toString(),
                                icon: Icons.bookmark_outlined,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (boughtProperties.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Bought Properties',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: boughtProperties.length,
                          itemBuilder: (context, index) {
                            final prop = boughtProperties[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                leading:
                                    (prop['images'] != null &&
                                        prop['images'].toString().isNotEmpty)
                                    ? Image.network(
                                        prop['images']
                                            .toString()
                                            .split(',')
                                            .first
                                            .trim(),
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 56,
                                        height: 56,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image,
                                          size: 28,
                                        ),
                                      ),
                                title: Text(prop['title'] ?? 'Property'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(prop['price'] ?? ''),
                                    if (prop['payment_method'] != null)
                                      Text(
                                        'Paid with: ${prop['payment_method']}',
                                      ),
                                    if (prop['payment_time'] != null)
                                      Text('Date: ${prop['payment_time']}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'No properties bought yet.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ],

                      if (userListings.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Your Listings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: userListings.length,
                          itemBuilder: (context, index) {
                            final property = userListings[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                leading: property.images.isNotEmpty
                                    ? (property.images.first.startsWith('/') ||
                                              property.images.first.startsWith(
                                                'file://',
                                              ))
                                          ? Image.file(
                                              File(property.images.first),
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.network(
                                              property.images.first,
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                            )
                                    : Container(
                                        width: 56,
                                        height: 56,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image,
                                          size: 28,
                                        ),
                                      ),
                                title: Text(
                                  property.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  property.price.startsWith('Tsh')
                                      ? property.price
                                      : 'Tsh ${property.price}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _editListing(property),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _deleteListing(property.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Account Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ProfileMenuItem(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        subtitle: 'Update your personal information',
                        onTap: () {
                          _showEditProfileDialog(context);
                        },
                      ),

                      ProfileMenuItem(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        subtitle: 'Update your password',
                        onTap: () {
                          _showChangePasswordDialog(context);
                        },
                      ),

                      const SizedBox(height: 24),

                      // Preferences Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Preferences',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ProfileMenuItem(
                        icon: Icons.notifications_outlined,
                        title: 'Push Notifications',
                        subtitle: 'Get notified about new properties',
                        showArrow: false,
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (value) async {
                            await _onNotificationToggle(value);
                          },
                          activeColor: const Color(0xFF4CAF50),
                        ),
                      ),

                      ProfileMenuItem(
                        icon: Icons.dark_mode_outlined,
                        title: 'Dark Mode',
                        subtitle: 'Switch to dark theme',
                        showArrow: false,
                        trailing: Switch(
                          value: widget.darkModeNotifier.value,
                          onChanged: (value) {
                            widget.darkModeNotifier.value = value;
                          },
                          activeColor: const Color(0xFF4CAF50),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Delete Account Button
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            _showDeleteAccountDialog(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.withAlpha(230),
                            side: BorderSide(color: Colors.red.withAlpha(77)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.delete_outline, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Delete Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Logout Button
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  _showLogoutDialog(context);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withAlpha(128),
                            foregroundColor: Colors.red.withAlpha(230),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.red.withAlpha(51),
                                width: 1,
                              ),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.logout, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Logout',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendEmailVerification() async {
    try {
      setState(() => _isLoading = true);
      await authService.value.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: displayName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await authService.value.updateProfile(
                    displayName: nameController.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {}); // Refresh the UI
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Change Password'),
          content: const Text(
            'We will send a password reset email to your registered email address.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await authService.value.sendPasswordResetEmail(userEmail);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Send Reset Email'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Account',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await authService.value.deleteAccount();
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/onboarding',
                      (Route<dynamic> route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.share, color: Color(0xFF2E7D32)),
                title: const Text('Share Profile'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code, color: Color(0xFF2E7D32)),
                title: const Text('QR Code'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Color(0xFF2E7D32)),
                title: const Text('Advanced Settings'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to logout from your account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await authService.value.signOut();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/onboarding',
                    (Route<dynamic> route) => false, // Clears all routes
                  );
                } catch (e) {
                  // Show error to user
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error signing out: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
