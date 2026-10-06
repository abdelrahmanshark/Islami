import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:islami/di/injection.config.dart';

/// App-wide service locator. Resolve dependencies with `getIt<Type>()`.
final GetIt getIt = GetIt.instance;

bool _isConfigured = false;

/// Registers every class annotated with @injectable / @lazySingleton.
///
/// Background isolates (Adhan alarm, download foreground task) have their own
/// [GetIt] instance, so their entry points must call this too. Calling it
/// again in the same isolate does nothing.
@InjectableInit()
void configureDependencies() {
  if (_isConfigured) return;
  getIt.init();
  _isConfigured = true;
}
