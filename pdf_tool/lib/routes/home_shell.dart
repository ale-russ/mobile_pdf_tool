// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class HomeShell extends StatelessWidget {
//   final Widget child;
//   const HomeShell({super.key, required this.child});

//   @override
//   Widget build(BuildContext context) {
//     final currentLocation = GoRouter.of(context).location;

//     int _getSelectedIndex() {
//       if (currentLocation.startsWith('/home/editor')) return 1;
//       if (currentLocation.startsWith('/home/viewer')) return 2;
//       if (currentLocation.startsWith('/home/settings')) return 3;
//       return 0;
//     }

//     void _onTap(int index) {
//       switch (index) {
//         case 0:
//           context.go('/home');
//           break;
//         case 1:
//           context.go('/home/editor');
//           break;
//         case 2:
//           context.go('/home/viewer');
//           break;
//         case 3:
//           context.go('/home/settings');
//           break;
//       }
//     }

//     return Scaffold(
//       body: child,
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _getSelectedIndex(),
//         onTap: _onTap,
//         selectedItemColor: Colors.red,
//         unselectedItemColor: Colors.grey,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Editor'),
//           BottomNavigationBarItem(icon: Icon(Icons.picture_as_pdf), label: 'Viewer'),
//           BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
//         ],
//       ),
//     );
//   }
// }
