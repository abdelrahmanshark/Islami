---
name: flutter-mvvm-architecture
description: Scaffold and organize Flutter projects with MVVM + provider, get_it/injectable DI, domain/data layering, shared utils (colors, styles, assets, routes, animations), and a consistent UI/UX animation system. Use when starting a new Flutter project, adding a feature/screen, reorganizing folders, setting up dependency injection, or adding page/tap/state animations.
---

# Flutter MVVM Architecture Skill

## When to use

- Starting a new Flutter app, or bringing an existing one into this structure.
- Adding a feature: model, data source, repository, ViewModel, screen, or widgets.
- Setting up or extending get_it/injectable DI.
- Adding animations, transitions, or loading/error/empty states.

## Workflow: new project

1. **Inspect first.** Read `pubspec.yaml`, the Dart SDK version, and `lib/`. Don't change anything
   until you understand the current structure.
2. **Dependencies.** Look up on pub.dev the latest stable versions **compatible with the project's
   Dart SDK** and add them with caret constraints:
   - dependencies: `provider`, `get_it`, `injectable`, plus what the app needs (`http`,
     `shared_preferences`, …)
   - dev_dependencies: `injectable_generator`, `build_runner`

   On PowerShell, quote caret versions (`flutter pub add "get_it:^x.y.z"`) or edit
   `pubspec.yaml` directly.
3. **Create the folder skeleton** (see "Folder template").
4. **Create utils:** `app_colors.dart`, `app_styles.dart`, `app_assets.dart`, `app_routes.dart`,
   `app_themes.dart`, `app_animations.dart`, `shared_preferences.dart`, `app_messenger.dart`.
5. **Create DI:** `lib/di/injection.dart` (see template). Call `configureDependencies()` first in
   `main()`.
6. **Create shared animation widgets** in `lib/ui/widget/`: `fade_in.dart`,
   `pressable_scale.dart`, `animated_icon_switcher.dart`.
7. **Wire `main.dart`:**
   - `WidgetsFlutterBinding.ensureInitialized()`, then `configureDependencies()`, then the
     startup services, then `runApp(AppProviders(child: MyApp()))`.
   - `MaterialApp` takes `theme: AppTheme.darkTheme` (or light), named `routes`, and
     `scaffoldMessengerKey: AppMessenger.scaffoldMessengerKey`.
8. **Generate:** run `dart run build_runner build`, then `flutter analyze` (it must be clean).

## Workflow: new feature

1. **Model:** check `lib/models/` first. Otherwise create `lib/models/<name>.dart` with a
   `fromJson` factory (and `toJson`/`copyWith` when needed).
2. **Data source:** create `lib/data/<feature>/<feature>_<local|remote>_data_source.dart`, mark it
   `@lazySingleton`. It does one job and handles errors with `log` + `rethrow`.
3. **Repository**, only if it combines sources or needs to be swappable:
   - the abstract class goes in `lib/domain/repositories/<feature>_repository.dart`;
   - the implementation goes in `lib/data/<feature>/<feature>_repository_impl.dart` with
     `@LazySingleton(as: <Feature>Repository)`.
4. **ViewModel:** create `lib/ui/<name>_view/view_model/<name>_view_model.dart` as an
   `@injectable` `ChangeNotifier` with constructor injection of abstract types.
5. **View:** create `lib/ui/<name>_view/<name>_view.dart`. It provides the ViewModel with
   `ChangeNotifierProvider(create: (_) => getIt<XViewModel>())` and contains only layout.
6. **Widgets:** one per file in `lib/ui/<name>_view/widget/`.
7. **Route:** add a `xRouteName` to `AppRoutes`, register it in `MaterialApp.routes`, and navigate
   from a ViewModel method.
8. **Finish:** run `dart run build_runner build`, then `flutter analyze`.

## Folder template

```
lib/
├── main.dart
├── di/injection.dart                 # + generated injection.config.dart (committed, never edited)
├── domain/repositories/x_repository.dart
├── data/x/
│   ├── x_repository_impl.dart
│   ├── x_local_data_source.dart
│   └── x_remote_data_source.dart
├── models/x.dart
├── services/x_service.dart
├── providers/app_providers.dart
├── ui/
│   ├── widget/                       # app-wide: fade_in, pressable_scale, animated_icon_switcher,
│   │                                 # screen_background, no_internet_retry_view
│   ├── home/
│   │   ├── home_view.dart
│   │   ├── view_model/home_view_model.dart
│   │   ├── widget/
│   │   └── tabs/<tab>_view/{<tab>_view.dart, view_model/, widget/}
│   └── <name>_view/{<name>_view.dart, view_model/, widget/}
└── utils/
```

## Hard rules (check every change)

- An abstract class and its implementation never share a folder. The implementation is named
  `<Abstract>Impl`.
- Nothing outside `ui/` imports from `ui/`. ViewModels depend on abstract repositories.
- Models live only in `lib/models/`. Pure helpers live in `lib/utils/`. `AppAssets` holds only
  constants (asset loading belongs in data sources; path builders belong in models).
- Never write functions that return widgets; create widget classes. Put each custom widget in its
  own file in a `widget/` folder.
- The ViewModel owns state, logic, data loading, and navigation. The View owns layout only.
- Every method gets a short `///` comment.
- Use `package:` imports only.
- Use `onChanged` instead of `TextEditingController` unless one is explicitly required.
- Colors come from `AppColors.<colorName>`. Styles come from `AppStyles.<color><Weight><size>`.
  Assets come from `AppAssets`. Routes come from `AppRoutes`. Never hardcode any of these.
- Use `getIt<T>()` only at composition points: main, AppProviders, provider `create`, screen
  `initState`, route builders, and isolate entry points.

## DI templates

```dart
// lib/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:{app}/di/injection.config.dart';

/// App-wide service locator. Resolve dependencies with `getIt<Type>()`.
final GetIt getIt = GetIt.instance;

bool _isConfigured = false;

/// Registers every annotated class. Background isolates have their own
/// [GetIt], so their entry points must call this too.
@InjectableInit()
void configureDependencies() {
  if (_isConfigured) return;
  getIt.init();
  _isConfigured = true;
}
```

```dart
@lazySingleton
class XRemoteDataSource { /* stateless HTTP / assets / prefs / channel */ }

@LazySingleton(as: XRepository)
class XRepositoryImpl implements XRepository {
  XRepositoryImpl(this._remote, this._local);
  final XRemoteDataSource _remote;
  final XLocalDataSource _local;
}

@injectable
class XViewModel extends ChangeNotifier {
  XViewModel(this._repository);
  final XRepository _repository;
}

@injectable
class DetailViewModel extends ChangeNotifier {
  DetailViewModel(@factoryParam this.item, this._repository);
  final Item item;
  final XRepository _repository;
}
// usage: getIt<DetailViewModel>(param1: item)
```

How to choose a lifetime:

| Case | Lifetime |
|---|---|
| Stateless data source or repository | `@lazySingleton` |
| App-wide shared state (player, connectivity, download manager, scheduler) | `@lazySingleton` |
| ViewModel with dependencies | `@injectable` |
| Per-operation state (current download) | `@injectable` |
| ViewModel that also needs screen args | `@factoryParam` |
| Has no dependencies, or a pure static helper | don't register |
| Eager startup work | `@singleton` (avoid; it breaks cheap isolate setup) |

Background isolate entry point:

```dart
@pragma('vm:entry-point')
Future<void> backgroundCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  await getIt<SomeService>().run();
}
```

## Provider templates

```dart
// Screen-owned ViewModel
ChangeNotifierProvider(
  create: (_) => getIt<XViewModel>(),
  child: const XViewBody(),
);

// App-wide (providers/app_providers.dart)
MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: getIt<AudioPlayerService>()), // get_it owns it
    ChangeNotifierProvider(create: (_) => getIt<FavoritesViewModel>()), // Provider owns it
  ],
  child: child,
);
```

- Use `Consumer` for sections, and `Selector` with a record for several values or ticking state.
- Use `context.read` inside callbacks.
- ViewModel state is public fields plus `notifyListeners()`, with `isLoading` and `failureMsg`.
- After every `await` that is followed by context use, check `context.mounted`.

## UI/UX animation system

### Tokens: `lib/utils/app_animations.dart`

```dart
import 'package:flutter/animation.dart';

/// Shared animation timings so motion feels consistent across the app.
class AppAnimations {
  static const Duration press = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration listMove = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeOutCubic;
  static const double pressedScale = 0.97;
}
```

Other approved values:
- 200 ms icon swaps.
- 250 ms toolbar show/hide (`easeInOut`).
- 300 ms content/title swaps and page jumps (`easeInOut`).
- 350 ms panel or mini-player slide (`easeOutCubic` in, `easeInCubic` out).
- 280–450 ms playful feedback (`easeOutBack`).
- 600 ms + 400 ms auto-scroll.

### Page transitions: set once in `AppTheme`

```dart
pageTransitionsTheme: const PageTransitionsTheme(
  builders: {
    TargetPlatform.android: ZoomPageTransitionsBuilder(
      backgroundColor: AppColors.blackColor, // avoids a white flash on dark UIs
    ),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
),
```

Don't write per-route `PageRouteBuilder`s. Navigate with `Navigator.pushNamed` and `AppRoutes`.
Splash → home uses `pushReplacementNamed`.

### Shared animation widgets (`lib/ui/widget/`)

```dart
/// Shrinks its child slightly while a finger is down on it,
/// giving instant tap feedback without delaying the tap itself.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;
  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;
  Offset _downPosition = Offset.zero;

  /// Updates the pressed state only when it actually changes.
  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  /// Starts the press animation where the finger touched.
  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _downPosition = event.position;
    _setPressed(true);
  }

  /// Releases the press when the finger moves away (e.g. list scrolling).
  void _onPointerMove(PointerMoveEvent event) {
    if ((event.position - _downPosition).distance > kTouchSlop) {
      _setPressed(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? AppAnimations.pressedScale : 1,
        duration: AppAnimations.press,
        curve: AppAnimations.curve,
        child: widget.child,
      ),
    );
  }
}
```

```dart
/// Quickly fades its child in when it first appears.
/// Give it a key that changes (e.g. `ValueKey('loading')`) to replay the fade.
class FadeIn extends StatefulWidget {
  const FadeIn({super.key, required this.child});
  final Widget child;
  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: AppAnimations.fast);
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _controller, curve: AppAnimations.curve);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
```

```dart
/// Scales and fades between icons when they change (e.g. play ↔ pause).
/// The child needs a key that changes with it, e.g. `ValueKey(isPlaying)`.
class AnimatedIconSwitcher extends StatelessWidget {
  const AnimatedIconSwitcher({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: child,
    );
  }
}
```

### Patterns to apply

- **Tappable cards:** `PressableScale(child: InkWell/GestureDetector(...))`.
- **Screen states:** use one `FadeIn` per state, each with its own key:

  ```dart
  if (vm.isLoading) {
    return const FadeIn(
      key: ValueKey('loading'),
      child: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
    );
  }
  if (vm.failureMsg != null) {
    return FadeIn(
      key: const ValueKey('failure'),
      child: NoInternetRetryView(message: vm.failureMsg!, onRefresh: vm.retry),
    );
  }
  if (vm.items.isEmpty) {
    return FadeIn(
      key: const ValueKey('empty'),
      child: Center(child: Text('No results', style: AppStyles.primaryBold20)),
    );
  }
  return FadeIn(key: const ValueKey('content'), child: XList(items: vm.items));
  ```

  `NoInternetRetryView` is the shared error widget: a message plus a refresh `IconButton`.
- **Bottom tabs:**
  - Use an `IndexedStack`, building each tab lazily on its first visit.
  - Wrap hidden tabs in `TickerMode(enabled: false)` and `ExcludeFocus`.
  - Wrap the selected tab in `FadeIn(key: ValueKey(index))`.
  - Selected nav icons get an `AnimatedContainer` pill (`fast`, `curve`).
- **Splash:**
  1. Preserve the native splash and precache images.
  2. Remove the native splash, then run one `AnimationController` (about 2.4 s) whose layers are
     staggered with `Interval`s (fade `easeOut`, slide `easeOutCubic`, logo scale
     `easeOutBack`).
  3. Hold about 0.9 s, then `pushReplacementNamed`.
- **Play buttons:** while loading, show a small spinner inside `AnimatedIconSwitcher`; otherwise
  show play/pause with `ValueKey(isPlaying)`.
- **Bottom panels or mini players:** use an `AnimatedSwitcher` with 350 ms
  `SizeTransition(axisAlignment: 1)` plus a fade. Animate content changes inside them with
  `AnimatedSize` and an `AnimatedSwitcher` (300 ms fade + slide-up).
- **Moving list items:** use a `TweenAnimationBuilder` for height factor and opacity
  (`listMove`). The ViewModel does `await Future.delayed(AppAnimations.listMove)` and only then
  reorders the lists.
- **Auto-scroll:** `animateTo` the active item (600 ms, then a 400 ms reveal, `easeInOut`).
  Scroll to the top when search is activated.
- **Micro-interactions:**
  - `AnimatedContainer` for active borders and glows.
  - `AnimatedDefaultTextStyle` for active text.
  - An `AnimatedSwitcher` scale + fade (280 ms, `easeOutBack`) for counters.
  - `TweenAnimationBuilder` for progress fills (450 ms, `easeOutCubic`).
  - `AnimatedScale(easeOutBack)` for completion badges.
  - `AnimatedRotation` (450 ms, `easeOutBack`) for decorative turns.
- **Toolbars over content:** a `Stack` with `Positioned`, `IgnorePointer`, `AnimatedSlide`, and
  `AnimatedOpacity` (250 ms, `easeInOut`), so hiding never resizes the content.
- **Snackbars:** floating, and call `hideCurrentSnackBar()` first. Put repeated messages in small
  helper functions. Services use `AppMessenger.showSnackBar`.
- **Overlays:** app-wide banners go in `MaterialApp.builder`, inside a `Stack` above `child`.
  Confirmations use `showDialog<bool>`; option pickers use `showModalBottomSheet`.
- **Performance:**
  - `precacheImage` neighbors and splash layers.
  - Parse large JSON with `compute()`.
  - Use `Selector` for ticking values.
  - Use a fixed-size `ScreenBackground` so overlays don't move it.

## Final checklist

- [ ] `flutter analyze` is clean, and `dart run build_runner build` ran after DI changes.
- [ ] No abstract class shares a folder with its `Impl`. ViewModels use abstract types.
- [ ] Data, domain, services, models, and utils never import from `ui/`.
- [ ] No hardcoded colors, styles, asset paths, or route names. No widget-returning functions.
- [ ] One widget per file in `widget/`. Every method has a `///` comment.
- [ ] Each background isolate entry point calls `configureDependencies()`.
- [ ] Taps use `PressableScale`, icon toggles use `AnimatedIconSwitcher`, state switches use a
      keyed `FadeIn`, and durations come from `AppAnimations`.
