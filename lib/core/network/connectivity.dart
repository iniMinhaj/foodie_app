// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';

// class NoInternetBanner extends StatelessWidget {
//   final Widget child;

//   const NoInternetBanner({super.key, required this.child});

//   @override
//   Widget build(BuildContext context, ) {
//   //  final isConnected = ref.watch(isConnectedProvider);

//     return Column(
//       children: [
//         // ── Banner — internet না থাকলে দেখায় ────────────────
//         AnimatedContainer(
//           duration: const Duration(milliseconds: 300),
//           height: isConnected ? 0 : 36,
//           color: Colors.red[700],
//           child: isConnected
//               ? const SizedBox.shrink()
//               : const Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
//                     SizedBox(width: 8),
//                     Text(
//                       'No internet connection',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//         ),

//         // ── Main content ─────────────────────────────────────
//         Expanded(child: child),
//       ],
//     );
//   }
// }
