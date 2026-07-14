import 'package:flutter/material.dart';

class NavButton extends StatelessWidget {
  const NavButton({
    super.key,
    this.outline = false,
    this.icon = '',
    required this.title,
    required this.destination,
  });

  final bool outline;
  final String icon;
  final String title;
  final String destination;

  @override
  Widget build(BuildContext context) {
    if (!outline) {
      return _ElevatedButton(icon: icon, title: title, route: destination);
    }
    return _OutlineButton(icon: icon, title: title, route: destination);
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.title,
    required this.route,
    this.icon = '',
  });

  final String title;
  final String icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => _navigateTo(context, route),
      child: Row(
        mainAxisAlignment: .center,
        children: [
          icon != ''
              ? Image(image: AssetImage('assets/icons/$icon.png'))
              : SizedBox(),
          SizedBox(width: 12),
          Text(title),
        ],
      ),
    );
  }
}

class _ElevatedButton extends StatelessWidget {
  const _ElevatedButton({
    required this.title,
    required this.route,
    this.icon = '',
  });

  final String title;
  final String icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _navigateTo(context, route),
      child: Row(
        mainAxisAlignment: .center,
        children: [
          icon != ''
              ? Image(image: AssetImage('assets/icons/$icon.png'))
              : SizedBox(),
          SizedBox(width: 12),
          Text(title),
        ],
      ),
    );
  }
}

// _navigateTo({required String destination}) {}

void _navigateTo(BuildContext context, String destination) {
  Navigator.pushNamed(context, destination);
}
