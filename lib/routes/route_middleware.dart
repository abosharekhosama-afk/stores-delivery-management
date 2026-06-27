import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/routes/routes.dart';

class RouteMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // إذا لم يكن المستخدم مسجلاً، وجهه لشاشة اختيار نوع الحساب
    return !AuthenticationRepository.instance.isAuthentication
        ? const RouteSettings(name: TRoutes.chooseUserType)
        : null;
  }

  /*RouteSettings? redirect(String? route) {
    return !AuthenticationRepository.instance.isAuthentication
        ? const RouteSettings(name: TRoutes.login)
        : null;
  }*/
}
