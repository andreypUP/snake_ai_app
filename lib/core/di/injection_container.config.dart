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
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart'
    as _i161;

import '../../domain/services/auth_service.dart' as _i109;
import '../../domain/services/classification_db_service.dart' as _i847;
import '../../domain/services/classification_sync_service.dart' as _i1040;
import '../../domain/services/hospital_service.dart' as _i242;
import '../../domain/services/mapbox_service.dart' as _i614;
import '../../domain/services/snake_info_service.dart' as _i995;
import '../../domain/services/snake_report_service.dart' as _i364;
import '../../domain/services/yolo_detector.dart' as _i511;
import '../network/network_info.dart' as _i932;
import '../network/network_info_module.dart' as _i482;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final networkInfoModule = _$NetworkInfoModule();
    gh.singleton<_i161.InternetConnection>(
      () => networkInfoModule.internetConnectionChecker,
    );
    gh.singleton<_i109.AuthService>(() => _i109.AuthService());
    gh.singleton<_i847.ClassificationDbService>(
      () => _i847.ClassificationDbService(),
    );
    gh.singleton<_i1040.ClassificationSyncService>(
      () => _i1040.ClassificationSyncService(),
    );
    gh.singleton<_i242.HospitalService>(() => _i242.HospitalService());
    gh.singleton<_i614.MapboxService>(() => _i614.MapboxService());
    gh.singleton<_i995.SnakeInfoService>(() => _i995.SnakeInfoService());
    gh.singleton<_i364.SnakeReportService>(() => _i364.SnakeReportService());
    gh.singleton<_i511.YoloDetector>(() => _i511.YoloDetector());
    gh.singleton<_i932.NetworkInfo>(
      () => _i932.NetworkInfoImpl(gh<_i161.InternetConnection>()),
    );
    return this;
  }
}

class _$NetworkInfoModule extends _i482.NetworkInfoModule {}
