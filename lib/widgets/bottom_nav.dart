import 'package:flutter/material.dart';

class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({super.key, this.onProfileReturn});

  final VoidCallback? onProfileReturn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(25)
                : Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          NavBarItem(
            icon: Icons.home_filled,
            isActive: true,
            onTap: () {
              Navigator.pushNamed(context, "/homePage");
            },
          ),
          AddNavBarItem(
            isActive: false,
            onTap: () {
              Navigator.pushNamed(context, "/addListing");
            },
          ),
          NavBarItem(
            icon: Icons.bookmark_outline,
            isActive: false,
            onTap: () {
              Navigator.pushNamed(context, "/bookmark");
            },
          ),
          NavBarItem(
            icon: Icons.person_outline,
            isActive: false,
            onTap: () async {
              await Navigator.pushNamed(context, "/profile");
              if (onProfileReturn != null) onProfileReturn!();
            },
          ),
        ],
      ),
    );
  }
}

class NavBarItem extends StatelessWidget {
  const NavBarItem({
    super.key,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 25,
        backgroundColor: isActive
            ? theme.primaryColor
            : const Color(0xff5d5d61),
        child: Icon(icon, color: isActive ? Colors.white : Colors.grey),
      ),
    );
  }
}

class AddNavBarItem extends StatelessWidget {
  const AddNavBarItem({super.key, required this.onTap, this.isActive = false});
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 25,
        backgroundColor: isActive
            ? theme.primaryColor
            : const Color(0xff5d5d61),
        child: Icon(Icons.add, color: isActive ? Colors.white : Colors.grey),
      ),
    );
  }
}
