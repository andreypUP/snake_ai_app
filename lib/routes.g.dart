// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$shellPageRoute];

RouteBase get $shellPageRoute => GoRouteData.$route(
  path: '/',
  factory: $ShellPageRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'ai_cam_page',
      name: 'ai_cam_page',
      factory: $AICamPageRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'report_page',
      name: 'report_page',
      factory: $ReportPageRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'map_page',
      name: 'map_page',
      factory: $MapPageRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'profile_page',
      name: 'profile_page',
      factory: $ProfilePageRoute._fromState,
    ),
  ],
);

mixin $ShellPageRoute on GoRouteData {
  static ShellPageRoute _fromState(GoRouterState state) => ShellPageRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AICamPageRoute on GoRouteData {
  static AICamPageRoute _fromState(GoRouterState state) => AICamPageRoute();

  @override
  String get location => GoRouteData.$location('/ai_cam_page');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ReportPageRoute on GoRouteData {
  static ReportPageRoute _fromState(GoRouterState state) => ReportPageRoute();

  @override
  String get location => GoRouteData.$location('/report_page');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MapPageRoute on GoRouteData {
  static MapPageRoute _fromState(GoRouterState state) => MapPageRoute();

  @override
  String get location => GoRouteData.$location('/map_page');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ProfilePageRoute on GoRouteData {
  static ProfilePageRoute _fromState(GoRouterState state) => ProfilePageRoute();

  @override
  String get location => GoRouteData.$location('/profile_page');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
