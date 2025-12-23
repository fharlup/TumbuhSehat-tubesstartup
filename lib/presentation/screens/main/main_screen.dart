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
import 'komunitas_screen.dart';
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

  final List<Widget> _pages = [
    const BerandaScreen(),
    ChatbotScreen(),
    KomunitasScreen(),
    BlocProvider(
      create: (_) => di.sl<ProfileCubit>(),
      child: const ProfilScreen(),
    ),
  ];

  final List<String> _iconNames = ['Beranda', 'Chatbot', 'Komunitas', 'Profil'];

  void _onScanPressed() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ScanScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_activeIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _onScanPressed,
        backgroundColor: TSColor.mainTosca.primary,
        shape: const CircleBorder(),
        child: SvgPicture.asset(
          Assets.icons.scan.path,
          colorFilter: ColorFilter.mode(
            TSColor.monochrome.pureWhite,
            BlendMode.srcIn,
          ),
          width: 32,
          height: 32,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
          tabBuilder: (int index, bool isActive) {
            final iconName = _iconNames[index];
            final color = isActive
                ? TSColor.mainTosca.primary
                : TSColor.monochrome.black;
            final style = isActive ? TSFont.bold.small : TSFont.regular.small;
            final assetPath = isActive
                ? 'assets/icons/$iconName Active.svg'
                : 'assets/icons/$iconName Inactive.svg';

            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(assetPath, width: 24, height: 24),
                const SizedBox(height: 4),
                Text(iconName, style: style.withColor(color)),
              ],
            );
          },
          activeIndex: _activeIndex,
          gapLocation: GapLocation.center,
          notchSmoothness: NotchSmoothness.softEdge,
          leftCornerRadius: 24,
          rightCornerRadius: 24,
          onTap: (index) => setState(() => _activeIndex = index),
        ),
      ),
    );
  }
}