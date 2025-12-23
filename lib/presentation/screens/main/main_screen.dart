// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

import '../../../core/theme/ts_color.dart';
import '../../../core/theme/ts_text_style.dart';
import '../../../gen/assets.gen.dart';
import '../../../injection_container.dart' as di;
import '../../cubit/beranda/beranda_cubit.dart';
import '../../cubit/profile/profile_cubit.dart';
import 'beranda_screen.dart';
import 'chatbot_screen.dart';
import 'profil_screen.dart';
import 'scan_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (context) => di.sl<BerandaCubit>())],
      child: const _MainScreenContent(),
    );
  }
}

class _MainScreenContent extends StatefulWidget {
  const _MainScreenContent();

  @override
  State<_MainScreenContent> createState() => __MainScreenContentState();
}

class __MainScreenContentState extends State<_MainScreenContent> {
  int _activeIndex = 0;

  // --- DAFTAR HALAMAN (SCAN PINDAH KE POSISI 3) ---
  final List<Widget> _pages = [
    const BerandaScreen(),
    const ChatbotScreen(),
    const ScanScreen(), // <-- Posisi 3 sekarang Scan
    BlocProvider(
      create: (_) => di.sl<ProfileCubit>(),
      child: const ProfilScreen(),
    ),
  ];

  // Nama file icon untuk referensi
  final List<String> _iconNames = ['Beranda', 'Chatbot', 'Scan', 'Profil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Tampilkan halaman
      body: _pages[_activeIndex],

      // --- TOMBOL TENGAH (FAB) DIHAPUS TOTAL DI SINI ---
      
      // --- NAVIGASI BAWAH ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 24,
              offset: const Offset(0, -15),
            ),
          ],
        ),
        child: AnimatedBottomNavigationBar.builder(
          height: 80,
          backgroundColor: TSColor.monochrome.white,
          itemCount: _pages.length,
          
          // --- SETTING PENTING: GAP DIHILANGKAN ---
          gapLocation: GapLocation.none, // Agar bar rata, tidak ada lubang tengah
          notchSmoothness: NotchSmoothness.smoothEdge,
          leftCornerRadius: 24,
          rightCornerRadius: 24,
          
          activeIndex: _activeIndex,
          onTap: (index) => setState(() => _activeIndex = index),
          
          // --- TAMPILAN ICON ---
          tabBuilder: (int index, bool isActive) {
            final color = isActive
                ? TSColor.mainTosca.primary
                : TSColor.monochrome.black;
            final style = isActive ? TSFont.bold.small : TSFont.regular.small;
            
            // Logika Label
            String label = _iconNames[index];
            
            // WIDGET ICON
            Widget iconWidget;

            // KHUSUS INDEX 2 (SCAN): Kita pakai Icon bawaan Flutter (Kamera)
            // agar tidak error mencari asset SVG yang belum ada.
            if (index == 2) {
              iconWidget = Icon(
                Icons.camera_alt_rounded,
                size: 28,
                color: color,
              );
            } else {
              // SELAIN SCAN: Pakai SVG dari Assets
              // Pastikan nama file: 'Beranda Active.svg', 'Chatbot Active.svg', dst.
              final assetPath = isActive
                  ? 'assets/icons/${_iconNames[index]} Active.svg'
                  : 'assets/icons/${_iconNames[index]} Inactive.svg';
              
              iconWidget = SvgPicture.asset(
                assetPath, 
                width: 24, 
                height: 24
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget,
                const SizedBox(height: 4),
                Text(label, style: style.withColor(color)),
              ],
            );
          },
        ),
      ),
    );
  }
}