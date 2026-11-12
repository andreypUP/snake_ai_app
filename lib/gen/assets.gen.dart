// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';

class $LibGen {
  const $LibGen();

  /// Directory path: lib/assets
  $LibAssetsGen get assets => const $LibAssetsGen();

  /// Directory path: lib/data
  $LibDataGen get data => const $LibDataGen();

  /// Directory path: lib/domain
  $LibDomainGen get domain => const $LibDomainGen();
}

class $AssetsDataGen {
  const $AssetsDataGen();

  /// File path: assets/data/hospitals.json
  String get hospitals => 'assets/data/hospitals.json';

  /// List of all assets
  List<String> get values => [hospitals];
}

class $LibAssetsGen {
  const $LibAssetsGen();

  /// File path: lib/assets/new_logo.webp
  AssetGenImage get newLogo => const AssetGenImage('lib/assets/new_logo.webp');

  /// List of all assets
  List<AssetGenImage> get values => [newLogo];
}

class $LibDataGen {
  const $LibDataGen();

  /// Directory path: lib/data/datasources
  $LibDataDatasourcesGen get datasources => const $LibDataDatasourcesGen();
}

class $LibDomainGen {
  const $LibDomainGen();

  /// Directory path: lib/domain/models
  $LibDomainModelsGen get models => const $LibDomainModelsGen();
}

class $LibDataDatasourcesGen {
  const $LibDataDatasourcesGen();

  /// File path: lib/data/datasources/results.json
  String get results => 'lib/data/datasources/results.json';

  /// File path: lib/data/datasources/safety.json
  String get safety => 'lib/data/datasources/safety.json';

  /// List of all assets
  List<String> get values => [results, safety];
}

class $LibDomainModelsGen {
  const $LibDomainModelsGen();

  /// File path: lib/domain/models/best_float32.tflite
  String get bestFloat32 => 'lib/domain/models/best_float32.tflite';

  /// File path: lib/domain/models/labels.txt
  String get labels => 'lib/domain/models/labels.txt';

  /// List of all assets
  List<String> get values => [bestFloat32, labels];
}

class Assets {
  const Assets._();

  static const $AssetsDataGen data = $AssetsDataGen();
  static const $LibGen lib = $LibGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
