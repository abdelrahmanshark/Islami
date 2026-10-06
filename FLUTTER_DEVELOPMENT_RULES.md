# Flutter Development Rules

Reusable rules for new Flutter projects. Replace `{app}` with the package name.

## 1. Code quality

- Write simple, beginner-readable Dart/Flutter. Prefer the clearest solution over clever ones.
- Use advanced syntax (records, patterns, extensions, `late`) only when it clearly helps, and add a
  short comment explaining it.
- Every method gets a short `///` comment saying what it does.
- Comments only explain intent or constraints the code cannot show. No change-log comments.
- Single Responsibility: each class/file/method has one job. DRY: reuse existing code before adding.
- Descriptive, consistent names. Use `const` constructors and widgets wherever possible.
- Use `package:{app}/...` imports only. Never use relative imports.
- Never use deprecated APIs. Assume the modern Flutter/Dart versions pinned by the project.
- Before adding or updating a package, check pub.dev for the latest stable version **that is
  compatible with the project's Dart SDK**. Use caret constraints (`^x.y.z`), never guess versions,
  and add no packages unless the task needs them.

## 2. Folder structure

```
lib/
├── main.dart
├── di/                     # injection.dart (+ generated injection.config.dart)
├── domain/repositories/    # abstract contracts only
├── data/<feature>/         # *_repository_impl.dart, *_local_data_source.dart, *_remote_data_source.dart
├── models/                 # every model, one per file
├── services/               # app-wide services (audio, notifications, location, background work…)
├── providers/              # app_providers.dart (app-wide MultiProvider)
├── ui/
│   ├── widget/             # widgets shared by the whole app
│   └── <name>_view/
│       ├── <name>_view.dart
│       ├── view_model/<name>_view_model.dart
│       └── widget/         # widgets used only by this screen
└── utils/                  # app_colors, app_styles, app_assets, app_routes, app_themes,
                            # app_animations, shared_preferences, app_messenger, network_utils…
```

- Nested or child screens live inside their parent's folder and follow the same
  `view_model/` + `widget/` layout.
- Subfolders are always singular: `widget/` and `view_model/` (not `widgets/`, `viewmodels/`).
- Never put models, helpers, or calculators inside `ui/`. Models go in `lib/models/`; pure helpers
  go in `lib/utils/`.

## 3. Architecture and dependency direction

- Layers: View → ViewModel → Repository (abstract) ← RepositoryImpl → DataSource.
  ViewModels may also use services from `services/`.
- Only `ui/` may import from `ui/`. `data/`, `domain/`, `services/`, `models/`, and `utils/` must
  never import from `ui/`.
- An abstract class and its implementation **must not** share a folder. Put the abstract class in
  `domain/repositories/x_repository.dart` and the implementation in
  `data/<feature>/x_repository_impl.dart`.
- Name implementations as the abstract name plus `Impl` (`XRepository` → `XRepositoryImpl`,
  `XService` → `XServiceImpl`). The file name matches the class (`x_repository_impl.dart`).
- ViewModels depend on the abstract type, never on `*Impl`.
- Add an abstraction only when it earns its place (a repository combining sources, or a real need
  to swap the implementation). A simple read-only feature can use its data source directly.
- Each data source has one job: JSON assets (`rootBundle`), HTTP, SharedPreferences, or one
  `MethodChannel`. It catches, calls `log(e.toString())`, and `rethrow`s.
- Repositories own the combining logic: cache-or-network, offline fallback, merging lists.
- Asset-loading code and asset path builders live in data sources or models, never in
  `app_assets.dart`. `AppAssets` holds only constants.

## 4. Dependency injection (get_it + injectable)

- `lib/di/injection.dart` exposes `final GetIt getIt = GetIt.instance;` and an idempotent
  `@InjectableInit() void configureDependencies()`.
- Call `configureDependencies()` first in `main()`. Also call it at the top of **every
  background-isolate entry point** (alarm callbacks, foreground tasks, workmanager), because each
  isolate has its own `GetIt`.
- Choose lifetimes as follows:
  - `@lazySingleton`: stateless data sources, `@LazySingleton(as: XRepository)` implementations,
    and app-wide services that hold shared state (audio player, connectivity, download manager,
    schedulers, notification services).
  - `@injectable` (factory): ViewModels with dependencies, and services that hold
    per-operation state (for example the current download's abort trigger).
  - `@factoryParam`: a ViewModel that also needs a screen argument. Resolve it with
    `getIt<XViewModel>(param1: arg)`.
  - Avoid eager `@singleton` unless startup really needs it, so registering inside background
    isolates stays free.
  - Don't register ViewModels that have no dependencies, or pure static helpers
    (calculators, formatters, `NetworkUtils`).
- Use constructor injection only (`XViewModel(this._repository)`). No `?? Default()` fallbacks,
  no `static instance` singletons, no service locator calls inside business classes.
- Call `getIt<T>()` only at composition points: `main.dart`, `AppProviders`,
  `ChangeNotifierProvider.create`, screen `initState` (when the screen owns its ViewModel), route
  builders, and isolate entry points. Widgets read shared services through Provider.
- If a class needs a `MethodChannel` or `http.Client`, it creates them internally as `final`
  fields. Don't register third-party types unless they are shared.
- After changing annotations, run `dart run build_runner build`. Never edit
  `injection.config.dart`. Commit it.

## 5. MVVM and state management (provider)

- **View:** UI and layout only. It calls ViewModel methods.
- **ViewModel** (`ChangeNotifier`): all screen state, business logic, data loading, and navigation
  methods. It never builds widgets and holds no lists of widgets.
- Expose state as public fields and call `notifyListeners()` after changes. Use `isLoading` plus a
  `failureMsg` (or `errorMessage`) string. Build user-facing error text from a shared helper
  (for example `NetworkUtils.failureMessageFor(e)`).
- Provide the screen ViewModel at the top of the screen with
  `ChangeNotifierProvider(create: (_) => getIt<XViewModel>())`.
- If a screen needs lifecycle hooks, create the ViewModel in `initState`, provide it with
  `ChangeNotifierProvider.value`, and dispose it in `dispose`.
- In `AppProviders`:
  - Provide get_it singletons with `ChangeNotifierProvider.value`, so Provider never disposes them.
  - Provide app-lifetime ViewModels with `create`, so Provider owns them.
- Read state with `Consumer` for whole sections, `Selector` (with a record for several values) to
  limit rebuilds such as per-second timers, and `context.read` inside callbacks.
- Navigation lives in ViewModel methods that take `BuildContext`, always as
  `Navigator.pushNamed(context, AppRoutes.x, arguments: …)`. Check `context.mounted` after every
  `await`.
- Text fields use `onChanged`. Use a `TextEditingController` only when explicitly required.
  Persist search text when the UX calls for it.

## 6. Widgets

- Every custom widget goes in its own file in the nearest `widget/` folder: the screen's folder,
  `ui/<parent>/widget/` when siblings share it, or `ui/widget/` when the whole app shares it.
- Never define a widget class inside another widget's file. Never write functions or methods
  that return widgets; create a widget class instead. Simple `Text` widgets don't need a file.
- Keep widgets presentation-focused. Use local `setState` only for purely visual state such as a
  pressed state or animation flags.

## 7. Utils (single source of truth)

- **Colors:** `AppColors` in `app_colors.dart`, named only by color (`primaryColor`, `blackColor`,
  `offWhite`, `lightGrey`). Add missing colors there.
- **Text styles:** `AppStyles` in `app_styles.dart`, named `{color}{Weight}{size}`
  (`whiteBold16`, `primaryBold24`). The color must come from `AppColors`.
- **Assets:** constants in `AppAssets` only. Never hardcode a path.
- **Routes:**
  - Every screen gets a `xRouteName` constant in `AppRoutes` and is registered in
    `MaterialApp.routes`.
  - Read arguments inside the route builder with `ModalRoute.of(context)!.settings.arguments as T`.
  - Never hardcode route names or push screen classes directly.
- **SharedPreferences:**
  - Keys go in one keys class.
  - Access goes through small top-level `getX()`/`saveX()` functions in `shared_preferences.dart`.
  - Call `reloadPreferences()` before reading values written by another isolate.
- **Theme:** `AppTheme` holds `ThemeData`, the `SystemUiOverlayStyle`, and the
  `pageTransitionsTheme`.
- **Global snackbars:** use an `AppMessenger` with a `scaffoldMessengerKey`, so services can
  show messages.
- Never duplicate a value that already exists in `utils/`.

## 8. UI/UX and animation rules

**Tokens.** Keep all shared timings in `utils/app_animations.dart` and use them instead of
literals:

```dart
class AppAnimations {
  static const Duration press = Duration(milliseconds: 120);    // tap feedback
  static const Duration fast = Duration(milliseconds: 220);     // tab/section/state switches
  static const Duration listMove = Duration(milliseconds: 300); // list item shrink/grow
  static const Curve curve = Curves.easeOutCubic;               // default curve
  static const double pressedScale = 0.97;                      // pressed card scale
}
```

**Duration scale.** Most animations should be short and responsive. Allowed beyond the tokens:

| Duration | Use |
|---|---|
| 200 ms | icon swaps |
| 250 ms | overlay bars (`easeInOut`) |
| 300 ms | content or title swaps, programmatic page jumps (`easeInOut`) |
| 350 ms | player or panel slide-in (`easeOutCubic` in, `easeInCubic` out) |
| 280–450 ms | playful feedback (`easeOutBack`): counters, check badges, rotation |
| 600 ms + 400 ms | auto-scroll (approach, then reveal) |

**Page transitions.** Configure them once in the theme and never per route. Use
`ZoomPageTransitionsBuilder` on Android and `CupertinoPageTransitionsBuilder` on iOS. On dark
apps, pass the dark `backgroundColor` so routes don't flash white.

**Splash.**
1. Preserve the native splash.
2. Precache the splash images, then remove the native splash.
3. Play one `AnimationController` whose layers are staggered with `Interval`s (fade, slide,
   scale).
4. Hold briefly, then `pushReplacementNamed` to home.

**Bottom-tab navigation.**
- Use an `IndexedStack` to keep tab state, and build each tab lazily on its first visit.
- Wrap hidden tabs in `TickerMode(enabled: false)` and `ExcludeFocus`.
- Fade the selected tab in using `fast`.
- Selected nav icons animate a pill background with `AnimatedContainer`.

**Tap feedback.** Wrap every tappable card in a shared `PressableScale` widget that:
- uses a raw `Listener`, so it never delays or steals the tap;
- scales to `pressedScale` over `press`;
- releases when the finger moves past `kTouchSlop`, so scrolling doesn't leave cards pressed.

**Icon toggles.**
- Use a shared `AnimatedIconSwitcher` (`AnimatedSwitcher` with scale and fade, 200 ms). The
  child must carry a changing `ValueKey`.
- Play buttons switch to a small `CircularProgressIndicator` while audio or content loads.

**Screen states** (loading → error → empty → content):
- Wrap each state in a shared `FadeIn` widget with a distinct `ValueKey`.
- **Loading:** a centered `CircularProgressIndicator(color: AppColors.primaryColor)`.
- **Error:** a shared retry view (message plus refresh `IconButton`). Offline-aware headers show
  a refresh icon only while offline.
- **Empty:** centered text in the standard title style.

**Snackbars.** Always floating, and call `hideCurrentSnackBar()` first. Use small shared helper
functions for repeated messages (no internet, playback failed).

**Lists.**
- When items move between lists (for example favorites), animate height and opacity with a
  `TweenAnimationBuilder` (`listMove`). The ViewModel awaits the same duration before reordering.
- Smoothly auto-scroll to the active item.
- Scroll back to the top when the search bar is focused.

**Micro-interactions.**
- `AnimatedContainer` for selected or active borders and glows.
- `AnimatedSwitcher` (scale and fade) for changing counters.
- `TweenAnimationBuilder` for progress fills.
- `AnimatedScale(easeOutBack)` for completion badges.
- `AnimatedSlide` plus `AnimatedOpacity` for show/hide toolbars. Overlay them so hiding never
  resizes the content.
- `AnimatedSize` around content that changes height.

**Perceived performance.**
- `precacheImage` neighbors and splash layers.
- Parse large JSON with `compute()`.
- Use `Selector` for frequently ticking state.
- Use one shared `ScreenBackground` that is sized from the screen height, so bottom overlays
  don't shift it.

**Reuse.** Animation widgets are shared widgets in `ui/widget/`. Don't re-implement fades,
press scales, or icon switches inline.

## 9. Background work and platform code

- Isolate entry points are top-level `@pragma('vm:entry-point')` functions. Each one calls
  `configureDependencies()` (and `DartPluginRegistrant.ensureInitialized()` when needed).
- Code that runs in the background never requests permissions or shows dialogs. Ask for
  permissions from UI-triggered code.
- Platform channels are wrapped in a data source or service, guarded by a platform check, and
  return safe defaults on `PlatformException`.
