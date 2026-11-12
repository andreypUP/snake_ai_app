import 'package:venom_shield_ph/presentation/pages/ai_cam.dart';
import 'package:venom_shield_ph/presentation/pages/shell_page.dart';
import 'package:venom_shield_ph/presentation/pages/report_page.dart';
import 'package:venom_shield_ph/presentation/pages/map_page.dart';
import 'package:venom_shield_ph/presentation/pages/profile_page.dart';
import 'package:venom_shield_ph/presentation/pages/classification_report_list_page.dart';
import 'package:venom_shield_ph/presentation/pages/classification_report_detail_page.dart';
import 'package:venom_shield_ph/presentation/pages/snake_class_list_page.dart';
import 'package:venom_shield_ph/presentation/pages/snake_class_detail_page.dart';
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
    TypedGoRoute<ProfilePageRoute>(
      path: 'profile_page',
      name: "profile_page",
    ),
    TypedGoRoute<ClassificationReportListPageRoute>(
      path: 'classification_reports',
      name: "classification_reports",
    ),
    TypedGoRoute<ClassificationReportDetailPageRoute>(
      path: 'classification_report/:reportId',
      name: "classification_report_detail",
    ),
    TypedGoRoute<SnakeClassListPageRoute>(
      path: 'snake_classes',
      name: "snake_classes",
    ),
    TypedGoRoute<SnakeClassDetailPageRoute>(
      path: 'snake_class/:snakeId',
      name: "snake_class_detail",
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


@immutable
class ProfilePageRoute extends GoRouteData with $ProfilePageRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProfilePage();
  }
}

@immutable
class ClassificationReportListPageRoute extends GoRouteData with $ClassificationReportListPageRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ClassificationReportListPage();
  }
}

@immutable
class ClassificationReportDetailPageRoute extends GoRouteData with $ClassificationReportDetailPageRoute {
  final String reportId;

  const ClassificationReportDetailPageRoute({required this.reportId});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ClassificationReportDetailPage(reportId: reportId);
  }
}

@immutable
class SnakeClassListPageRoute extends GoRouteData with $SnakeClassListPageRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SnakeClassListPage();
  }
}

@immutable
class SnakeClassDetailPageRoute extends GoRouteData with $SnakeClassDetailPageRoute {
  final String snakeId;

  const SnakeClassDetailPageRoute({required this.snakeId});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SnakeClassDetailPage(snakeId: snakeId);
  }
}