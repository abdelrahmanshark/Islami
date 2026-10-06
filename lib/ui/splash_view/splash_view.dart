import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:islami/ui/splash_view/view_model/splash_view_model.dart';
import 'package:islami/ui/splash_view/widget/splash_background.dart';
import 'package:islami/ui/splash_view/widget/splash_branding.dart';
import 'package:islami/ui/splash_view/widget/splash_lamp.dart';
import 'package:islami/ui/splash_view/widget/splash_logo.dart';
import 'package:islami/ui/splash_view/widget/splash_mosque.dart';
import 'package:islami/ui/splash_view/widget/splash_wheel.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';

/// Figma splash with full motion: lamp, wheels, logo, and branding.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  /// Design frame size from Figma (430 x 932).
  static const double _designWidth = 430;
  static const double _designHeight = 932;

  late final SplashViewModel _viewModel;
  late final AnimationController _entranceController;

  late final Animation<double> _bgFade;
  late final Animation<double> _mosqueFade;
  late final Animation<double> _mosqueScale;
  late final Animation<double> _lampSlide;
  late final Animation<double> _lampFade;
  late final Animation<double> _wheelFade;
  late final Animation<double> _leftWheelSlide;
  late final Animation<double> _rightWheelSlide;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoSlide;
  late final Animation<double> _logoScale;
  late final Animation<double> _brandingFade;
  late final Animation<double> _brandingSlide;

  @override
  void initState() {
    super.initState();
    _viewModel = SplashViewModel();

    _entranceController = AnimationController(
      vsync: this,
      duration: _viewModel.animationDuration,
    );

    _bgFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
    );

    _mosqueFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.05, 0.35, curve: Curves.easeOut),
    );
    _mosqueScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.05, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    // Lamp drops from above into its Figma position.
    _lampSlide = Tween<double>(begin: -1.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _lampFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.1, 0.35, curve: Curves.easeOut),
    );

    // Wheels slide in from outside the screen edges.
    _wheelFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
    );
    _leftWheelSlide = Tween<double>(begin: -1.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _rightWheelSlide = Tween<double>(begin: 1.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    // Center logo rises and settles.
    _logoSlide = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.75, curve: Curves.easeOutBack),
      ),
    );

    // Branding rises from the bottom last.
    _brandingSlide = Tween<double>(begin: 1.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _brandingFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSplash();
    });
  }

  /// Precaches layers, removes native splash, then plays full motion.
  Future<void> _startSplash() async {
    await Future.wait([
      precacheImage(const AssetImage(AppAssets.splashBg), context),
      precacheImage(const AssetImage(AppAssets.splashLogo), context),
      precacheImage(const AssetImage(AppAssets.splashLamp), context),
      precacheImage(const AssetImage(AppAssets.splashMosque), context),
      precacheImage(const AssetImage(AppAssets.splashWheelLeft), context),
      precacheImage(const AssetImage(AppAssets.splashWheelRight), context),
      precacheImage(const AssetImage(AppAssets.splashBranding), context),
    ]);

    if (!mounted) return;

    FlutterNativeSplash.remove();

    await _entranceController.forward();
    if (!mounted) return;

    await Future<void>.delayed(_viewModel.holdDuration);
    if (!mounted) return;

    _viewModel.goToHome(context);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  /// Converts a Figma X value to a fraction of design width.
  double _x(double value) => value / _designWidth;

  /// Converts a Figma Y value to a fraction of design height.
  double _y(double value) => value / _designHeight;

  /// Converts a Figma width to a fraction of design width.
  double _w(double value) => value / _designWidth;

  /// Converts a Figma height to a fraction of design height.
  double _h(double value) => value / _designHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: AnimatedBuilder(
        animation: _entranceController,
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final leftWheelWidth = width * _w(87);
              final rightWheelWidth = width * _w(101);

              return Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: _bgFade.value,
                    child: const SplashBackground(),
                  ),

                  // Top mosque outline — Figma: x69 y57 w291 h157
                  Positioned(
                    left: width * _x(69),
                    top: height * _y(57),
                    width: width * _w(291),
                    height: height * _h(157),
                    child: Opacity(
                      opacity: _mosqueFade.value,
                      child: Transform.scale(
                        scale: _mosqueScale.value,
                        child: const SplashMosque(),
                      ),
                    ),
                  ),

                  // Left wheels slide in from left — Figma: x0 y214 w87 h187
                  Positioned(
                    left: _leftWheelSlide.value * leftWheelWidth,
                    top: height * _y(214),
                    width: leftWheelWidth,
                    height: height * _h(187),
                    child: Opacity(
                      opacity: _wheelFade.value,
                      child: const SplashWheel(isLeft: true),
                    ),
                  ),

                  // Right wheels slide in from right — Figma: x329 y604 w101 h216
                  Positioned(
                    left: width * _x(329) +
                        (_rightWheelSlide.value * rightWheelWidth),
                    top: height * _y(604),
                    width: rightWheelWidth,
                    height: height * _h(216),
                    child: Opacity(
                      opacity: _wheelFade.value,
                      child: const SplashWheel(isLeft: false),
                    ),
                  ),

                  // Lamp drops down — Figma: x329 y0 w88 h313
                  Positioned(
                    left: width * _x(329),
                    top: height * _y(0) +
                        (_lampSlide.value * height * _h(313)),
                    width: width * _w(88),
                    height: height * _h(313),
                    child: Opacity(
                      opacity: _lampFade.value,
                      child: const SplashLamp(),
                    ),
                  ),

                  // Center logo — Figma: x127 y341 w174 h232
                  Positioned(
                    left: width * _x(127),
                    top: height * _y(341) +
                        (_logoSlide.value * height * 0.25),
                    width: width * _w(174),
                    height: height * _h(232),
                    child: Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: const SplashLogo(),
                      ),
                    ),
                  ),

                  // Branding rises from bottom — Figma: x93 y792 w244 h108
                  Positioned(
                    left: width * _x(93),
                    top: height * _y(792) +
                        (_brandingSlide.value * height * 0.2),
                    width: width * _w(244),
                    height: height * _h(108),
                    child: Opacity(
                      opacity: _brandingFade.value,
                      child: const SplashBranding(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
