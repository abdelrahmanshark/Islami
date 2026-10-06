// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:islami/data/azkar/azkar_local_data_source.dart' as _i365;
import 'package:islami/data/azkar/azkar_repository_impl.dart' as _i144;
import 'package:islami/data/jews_in_quran/jews_in_quran_local_data_source.dart'
    as _i241;
import 'package:islami/data/moshaf/moshaf_local_data_source.dart' as _i254;
import 'package:islami/data/pillars_of_islam/pillars_of_islam_local_data_source.dart'
    as _i552;
import 'package:islami/data/prophet_seerah/prophet_seerah_local_data_source.dart'
    as _i741;
import 'package:islami/data/quran_download/downloaded_audio_local_data_source.dart'
    as _i905;
import 'package:islami/data/quran_download/downloaded_audio_repository_impl.dart'
    as _i248;
import 'package:islami/data/quran_download/quran_media_store_data_source.dart'
    as _i669;
import 'package:islami/data/quran_stories/quran_stories_local_data_source.dart'
    as _i549;
import 'package:islami/data/radio/mshary_local_data_source.dart' as _i316;
import 'package:islami/data/radio/radio_remote_data_source.dart' as _i958;
import 'package:islami/data/radio/radio_repository_impl.dart' as _i76;
import 'package:islami/data/religion_and_life_program/religion_and_life_program_local_data_source.dart'
    as _i621;
import 'package:islami/data/riyad_assalihin/riyad_assalihin_local_data_source.dart'
    as _i230;
import 'package:islami/data/riyad_assalihin/riyad_assalihin_repository_impl.dart'
    as _i996;
import 'package:islami/data/sermons/sermons_local_data_source.dart' as _i547;
import 'package:islami/data/sharawy/sharawy_local_data_source.dart' as _i246;
import 'package:islami/data/sharawy_lectures/sharawy_lectures_local_data_source.dart'
    as _i432;
import 'package:islami/data/stories_of_prophets/stories_of_prophets_local_data_source.dart'
    as _i624;
import 'package:islami/data/time/time_local_data_source.dart' as _i1035;
import 'package:islami/data/time/time_remote_data_source.dart' as _i175;
import 'package:islami/data/time/time_repository_impl.dart' as _i275;
import 'package:islami/data/women_in_islam/women_in_islam_local_data_source.dart'
    as _i686;
import 'package:islami/domain/repositories/azkar_repository.dart' as _i145;
import 'package:islami/domain/repositories/downloaded_audio_repository.dart'
    as _i601;
import 'package:islami/domain/repositories/radio_repository.dart' as _i1025;
import 'package:islami/domain/repositories/riyad_assalihin_repository.dart'
    as _i528;
import 'package:islami/domain/repositories/time_repository.dart' as _i904;
import 'package:islami/models/reciters_response.dart' as _i613;
import 'package:islami/services/adhan_alarm_scheduler.dart' as _i389;
import 'package:islami/services/audio_player_service.dart' as _i371;
import 'package:islami/services/call_audio_guard.dart' as _i28;
import 'package:islami/services/connectivity_monitor.dart' as _i823;
import 'package:islami/services/device_sensor_service.dart' as _i231;
import 'package:islami/services/device_storage_service.dart' as _i993;
import 'package:islami/services/download_notification_service.dart' as _i122;
import 'package:islami/services/prayer_widget_updater.dart' as _i246;
import 'package:islami/services/quran_audio_download_service.dart' as _i53;
import 'package:islami/services/quran_download_manager.dart' as _i674;
import 'package:islami/services/user_location_service.dart' as _i314;
import 'package:islami/services/weekly_notification_service.dart' as _i369;
import 'package:islami/ui/downloads_view/view_model/downloads_view_model.dart'
    as _i506;
import 'package:islami/ui/home/tabs/hadith_screen/view_model/hadith_view_model.dart'
    as _i511;
import 'package:islami/ui/home/tabs/moshaf_screen/view_model/moshaf_hub_view_model.dart'
    as _i692;
import 'package:islami/ui/home/tabs/moshaf_screen/view_model/moshaf_view_model.dart'
    as _i822;
import 'package:islami/ui/home/tabs/radio_screen/view_model/radio_view_model.dart'
    as _i259;
import 'package:islami/ui/home/tabs/radio_screen/view_model/reciter_download_view_model.dart'
    as _i137;
import 'package:islami/ui/home/tabs/sebha_screen/view_model/sebha_view_model.dart'
    as _i196;
import 'package:islami/ui/home/tabs/time_screen/view_model/time_view_model.dart'
    as _i830;
import 'package:islami/ui/qibla_view/view_model/qibla_view_model.dart' as _i601;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i365.AzkarLocalDataSource>(
      () => _i365.AzkarLocalDataSource(),
    );
    gh.lazySingleton<_i241.JewsInQuranLocalDataSource>(
      () => _i241.JewsInQuranLocalDataSource(),
    );
    gh.lazySingleton<_i254.MoshafLocalDataSource>(
      () => _i254.MoshafLocalDataSource(),
    );
    gh.lazySingleton<_i552.PillarsOfIslamLocalDataSource>(
      () => _i552.PillarsOfIslamLocalDataSource(),
    );
    gh.lazySingleton<_i741.ProphetSeerahLocalDataSource>(
      () => _i741.ProphetSeerahLocalDataSource(),
    );
    gh.lazySingleton<_i905.DownloadedAudioLocalDataSource>(
      () => _i905.DownloadedAudioLocalDataSource(),
    );
    gh.lazySingleton<_i669.QuranMediaStoreDataSource>(
      () => _i669.QuranMediaStoreDataSource(),
    );
    gh.lazySingleton<_i549.QuranStoriesLocalDataSource>(
      () => _i549.QuranStoriesLocalDataSource(),
    );
    gh.lazySingleton<_i316.MsharyLocalDataSource>(
      () => _i316.MsharyLocalDataSource(),
    );
    gh.lazySingleton<_i958.RadioRemoteDataSource>(
      () => _i958.RadioRemoteDataSource(),
    );
    gh.lazySingleton<_i621.ReligionAndLifeProgramLocalDataSource>(
      () => _i621.ReligionAndLifeProgramLocalDataSource(),
    );
    gh.lazySingleton<_i230.RiyadAssalihinLocalDataSource>(
      () => _i230.RiyadAssalihinLocalDataSource(),
    );
    gh.lazySingleton<_i547.SermonsLocalDataSource>(
      () => _i547.SermonsLocalDataSource(),
    );
    gh.lazySingleton<_i432.SharawyLecturesLocalDataSource>(
      () => _i432.SharawyLecturesLocalDataSource(),
    );
    gh.lazySingleton<_i624.StoriesOfProphetsLocalDataSource>(
      () => _i624.StoriesOfProphetsLocalDataSource(),
    );
    gh.lazySingleton<_i1035.TimeLocalDataSource>(
      () => _i1035.TimeLocalDataSource(),
    );
    gh.lazySingleton<_i175.TimeRemoteDataSource>(
      () => _i175.TimeRemoteDataSource(),
    );
    gh.lazySingleton<_i686.WomenInIslamLocalDataSource>(
      () => _i686.WomenInIslamLocalDataSource(),
    );
    gh.lazySingleton<_i28.CallAudioGuard>(() => _i28.CallAudioGuard());
    gh.lazySingleton<_i823.ConnectivityMonitor>(
      () => _i823.ConnectivityMonitor(),
    );
    gh.lazySingleton<_i231.DeviceSensorService>(
      () => _i231.DeviceSensorService(),
    );
    gh.lazySingleton<_i993.DeviceStorageService>(
      () => _i993.DeviceStorageService(),
    );
    gh.lazySingleton<_i122.DownloadNotificationService>(
      () => _i122.DownloadNotificationService(),
    );
    gh.lazySingleton<_i246.PrayerWidgetUpdater>(
      () => _i246.PrayerWidgetUpdater(),
    );
    gh.lazySingleton<_i314.UserLocationService>(
      () => _i314.UserLocationService(),
    );
    gh.lazySingleton<_i369.WeeklyNotificationService>(
      () => _i369.WeeklyNotificationService(),
    );
    gh.factory<_i601.QiblaViewModel>(
      () => _i601.QiblaViewModel(gh<_i231.DeviceSensorService>()),
    );
    gh.lazySingleton<_i371.AudioPlayerService>(
      () => _i371.AudioPlayerService(gh<_i28.CallAudioGuard>()),
    );
    gh.factory<_i692.MoshafHubViewModel>(
      () => _i692.MoshafHubViewModel(gh<_i254.MoshafLocalDataSource>()),
    );
    gh.factory<_i822.MoshafViewModel>(
      () => _i822.MoshafViewModel(gh<_i254.MoshafLocalDataSource>()),
    );
    gh.lazySingleton<_i145.AzkarRepository>(
      () => _i144.AzkarRepositoryImpl(gh<_i365.AzkarLocalDataSource>()),
    );
    gh.lazySingleton<_i528.RiyadAssalihinRepository>(
      () => _i996.RiyadAssalihinRepositoryImpl(
        gh<_i230.RiyadAssalihinLocalDataSource>(),
      ),
    );
    gh.factory<_i196.SebhaViewModel>(
      () => _i196.SebhaViewModel(gh<_i145.AzkarRepository>()),
    );
    gh.factory<_i511.HadithViewModel>(
      () => _i511.HadithViewModel(gh<_i528.RiyadAssalihinRepository>()),
    );
    gh.lazySingleton<_i1025.RadioRepository>(
      () => _i76.RadioRepositoryImpl(
        gh<_i958.RadioRemoteDataSource>(),
        gh<_i316.MsharyLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i601.DownloadedAudioRepository>(
      () => _i248.DownloadedAudioRepositoryImpl(
        gh<_i905.DownloadedAudioLocalDataSource>(),
        gh<_i669.QuranMediaStoreDataSource>(),
      ),
    );
    gh.lazySingleton<_i246.SharawyLocalDataSource>(
      () => _i246.SharawyLocalDataSource(
        gh<_i549.QuranStoriesLocalDataSource>(),
        gh<_i741.ProphetSeerahLocalDataSource>(),
        gh<_i686.WomenInIslamLocalDataSource>(),
        gh<_i621.ReligionAndLifeProgramLocalDataSource>(),
        gh<_i432.SharawyLecturesLocalDataSource>(),
        gh<_i552.PillarsOfIslamLocalDataSource>(),
        gh<_i241.JewsInQuranLocalDataSource>(),
        gh<_i624.StoriesOfProphetsLocalDataSource>(),
      ),
    );
    gh.factory<_i506.DownloadsViewModel>(
      () => _i506.DownloadsViewModel(
        gh<_i601.DownloadedAudioRepository>(),
        gh<_i371.AudioPlayerService>(),
      ),
    );
    gh.lazySingleton<_i904.TimeRepository>(
      () => _i275.TimeRepositoryImpl(
        gh<_i175.TimeRemoteDataSource>(),
        gh<_i1035.TimeLocalDataSource>(),
        gh<_i314.UserLocationService>(),
      ),
    );
    gh.factory<_i259.RadioViewModel>(
      () => _i259.RadioViewModel(
        gh<_i1025.RadioRepository>(),
        gh<_i547.SermonsLocalDataSource>(),
        gh<_i246.SharawyLocalDataSource>(),
        gh<_i601.DownloadedAudioRepository>(),
        gh<_i371.AudioPlayerService>(),
      ),
    );
    gh.factory<_i53.QuranAudioDownloadService>(
      () => _i53.QuranAudioDownloadService(
        gh<_i601.DownloadedAudioRepository>(),
        gh<_i669.QuranMediaStoreDataSource>(),
        gh<_i993.DeviceStorageService>(),
      ),
    );
    gh.lazySingleton<_i389.AdhanAlarmScheduler>(
      () => _i389.AdhanAlarmScheduler(
        gh<_i904.TimeRepository>(),
        gh<_i246.PrayerWidgetUpdater>(),
      ),
    );
    gh.factory<_i830.TimeViewModel>(
      () => _i830.TimeViewModel(
        gh<_i904.TimeRepository>(),
        gh<_i314.UserLocationService>(),
        gh<_i389.AdhanAlarmScheduler>(),
        gh<_i246.PrayerWidgetUpdater>(),
      ),
    );
    gh.lazySingleton<_i674.QuranDownloadManager>(
      () => _i674.QuranDownloadManager(gh<_i53.QuranAudioDownloadService>()),
    );
    gh.factoryParam<_i137.ReciterDownloadViewModel, _i613.Reciters, dynamic>(
      (reciter, _) => _i137.ReciterDownloadViewModel(
        reciter,
        gh<_i601.DownloadedAudioRepository>(),
        gh<_i674.QuranDownloadManager>(),
      ),
    );
    return this;
  }
}
