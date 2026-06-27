import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/layouts/headers/headers.dart';
import 'package:stors_admin_panel/common/widgets/layouts/sidebars/sidebar.dart';

class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key, this.body});
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Expanded(child: Sidebar()),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                const Headers(), // الهيدر الثابت
                Expanded(child: body ?? const SizedBox()), // المحتوى المتغير
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/*
class DesktopLayout extends StatelessWidget {
  DesktopLayout({super.key, this.body});
  final Widget? body;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: Row(
        children: [
          const Expanded(child: Sidebar()),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                children: [const Headers(), body ?? const SizedBox()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/
