import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/route_manager.dart';
import 'package:stors_admin_panel/routes/app_routes.dart';
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:stors_admin_panel/utils/constants/text_strings.dart';
import 'package:stors_admin_panel/utils/theme/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      // --- إعدادات اللغة العربية والاتجاه ---
      locale: const Locale('ar', 'SA'), // تحديد اللغة الافتراضية كعربية
      fallbackLocale: const Locale('ar', 'SA'),

      supportedLocales: const [Locale('ar', 'SA')],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: TTexts.appName,
      themeMode: ThemeMode.system,
      showSemanticsDebugger: false,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      getPages: AppRoutes.pages,
      initialRoute: TRoutes.chooseUserType,

      // unknownRoute: ,
    );
  }
}
