import 'package:flutter/material.dart';

import '../surveillance_page.dart';

class SurveillanceFilterTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const SurveillanceFilterTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 42,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: SurveillancePage.deepBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: SurveillancePage.deepBlue),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: SurveillancePage.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: SurveillancePage.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
      onTap: onTap,
    );
  }
}

class SurveillanceSheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const SurveillanceSheetHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: SurveillancePage.textDark,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: SurveillancePage.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
