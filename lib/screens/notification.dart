import 'package:flutter/material.dart';
import 'package:real_estate/models/propert_services.dart';
import 'package:real_estate/widgets/bottom_nav.dart';
import 'package:real_estate/models/property.dart';


class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Property> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final loadedProperties = await PropertyService.loadMockProperties();
      setState(() {
        notifications = loadedProperties.take(5).toList(); // Mock 5 notifications
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load notifications: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: true,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: theme.primaryColor,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.primaryColor,
                            border: Border.all(color: Colors.white),
                          ),
                          child: const Icon(Icons.home_outlined, color: Colors.white),
                        ),
                        const Spacer(),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Notifications",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.notifications, color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  notifications.length.toString(),
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                                ),
                                const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.settings, color: Colors.white),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.4)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : notifications.isEmpty
                              ? const Center(child: Text('No notifications'))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: notifications.length,
                                  itemBuilder: (context, index) {
                                    final property = notifications[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: ListTile(
                                          leading: const CircleAvatar(
                                            backgroundColor: Colors.green,
                                            child: Text('Active', style: TextStyle(color: Colors.white)),
                                          ),
                                          title: Text(
                                            property.title,
                                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                property.location,
                                                style: theme.textTheme.bodySmall,
                                              ),
                                              Text(
                                                property.price,
                                                style: theme.textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                          trailing: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.location_on, color: Colors.grey),
                                              SizedBox(width: 8),
                                              Icon(Icons.message, color: Colors.grey),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 80,
            right: 80,
            child: HomeBottomNavBar(),
          ),
        ],
      ),
    );
  }
}