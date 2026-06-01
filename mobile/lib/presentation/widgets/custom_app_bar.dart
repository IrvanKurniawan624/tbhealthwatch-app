import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;

  const CustomAppBar({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: showBackButton ? const BackButton(color: Colors.black) : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.health_and_safety, color: Colors.blue),
          ),
          const SizedBox(width: 8),
          const Text(
            "TB Health Watch",
            style: TextStyle(color: Color(0xFF0052CC), fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
