import 'package:flutter/material.dart';
import 'package:flutter_backtome/features/app_updates/presentation/pages/settings_page.dart';
import 'package:flutter_backtome/features/admin/presentation/pages/user_list_page.dart';
import 'package:flutter_backtome/features/auth/presentation/pages/create_account_page.dart';
import 'package:flutter_backtome/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_backtome/features/claims/presentation/pages/claimed_objects_page.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/pages/add_lost_object_page.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/pages/lost_object_points_page.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/pages/lost_object_pickup_page.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/pages/user_home_page.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/pages/user_lost_objects_page.dart';
import 'package:flutter_backtome/features/users/presentation/pages/user_account_page.dart';

class AppRouter {
  static const login = '/login';
  static const createAccount = '/create-account';
  static const userHome = '/user';
  static const adminHome = '/admin';
  static const account = '/account';
  static const addLostObject = '/lost-objects/add';
  static const myLostObjects = '/lost-objects/mine';
  static const claimedObjects = '/claims';
  static const pickup = '/lost-objects/pickup';
  static const lostObjectPoints = '/lost-objects/points';
  static const users = '/admin/users';
  static const settingsRoute = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    late final Widget page;

    switch (settings.name) {
      case login:
        page = PageLogin();
        break;
      case createAccount:
        page = PageCrearCuenta();
        break;
      case userHome:
        page = PageAppGeneral();
        break;
      case adminHome:
        page = PageAppGeneral();
        break;
      case account:
        page = UserAccountPage();
        break;
      case addLostObject:
        page = AddLostObjectPage();
        break;
      case myLostObjects:
        page = LostObjectsPage();
        break;
      case claimedObjects:
        page = ClaimedObjectsPage();
        break;
      case pickup:
        page = LostObjectPickupPage();
        break;
      case lostObjectPoints:
        page = const LostObjectPointsPage();
        break;
      case users:
        page = UserListPage();
        break;
      case settingsRoute:
        page = const SettingsPage();
        break;
      default:
        page = PageLogin();
        break;
    }

    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
