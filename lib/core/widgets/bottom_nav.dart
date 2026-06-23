import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool seniorMode;
  final int unreadAvvisi;

  const BottomNav({
    required this.currentIndex,
    required this.onTap,
    this.seniorMode = false,
    this.unreadAvvisi = 0,
  });

  @override
  Widget build(BuildContext context) {
    final style =
        seniorMode ? TextStyle(fontSize: 14) : TextStyle(fontSize: 12);

    Widget avvisiIcon = const Icon(Icons.mail);
    if (unreadAvvisi > 0) {
      avvisiIcon = Badge(
        label: Text('$unreadAvvisi', style: const TextStyle(fontSize: 10)),
        child: const Icon(Icons.mail),
      );
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Segnala'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Prenota',
        ),
        BottomNavigationBarItem(icon: avvisiIcon, label: 'Avvisi'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Storico'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilo'),
      ],
      selectedLabelStyle: style,
      unselectedLabelStyle: style,
    );
  }
}
