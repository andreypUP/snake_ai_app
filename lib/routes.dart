import 'package:venom_shield_ph/presentation/pages/ai_cam.dart';
import 'package:venom_shield_ph/presentation/pages/shell_page.dart';
import 'package:venom_shield_ph/presentation/pages/report_page.dart';
import 'package:venom_shield_ph/presentation/pages/map_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
part 'routes.g.dart';

@TypedGoRoute<ShellPageRoute>(
  path: "/",
  routes: [
    TypedGoRoute<AICamPageRoute>(
      path: 'ai_cam_page',
      name: "ai_cam_page",
    ),
    TypedGoRoute<ReportPageRoute>(
      path: 'report_page',
      name: "report_page",
    ),
    TypedGoRoute<MapPageRoute>(
      path: 'map_page',
      name: "map_page",
    ),
  ],
)

@immutable
class ShellPageRoute extends GoRouteData with $ShellPageRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ShellPage();
  }
}

@immutable
class AICamPageRoute extends GoRouteData with $AICamPageRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AICamPage();
  }
}

@immutable
class ReportPageRoute extends GoRouteData with $ReportPageRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ReportPage();
  }
}

@immutable
class MapPageRoute extends GoRouteData with $MapPageRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MapPage();
  }
}