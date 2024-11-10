import 'package:fl_live_launcher/apps.dart';
import 'package:fl_live_launcher/phone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_live_launcher/home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Flutter Launcher',
        darkTheme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        ),
        theme: ThemeData(  
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                switch (settings.name) {
                  case "apps":
                    return AppsPage();
                  case "phone":
                    return PhonePage();
                  default:
                    return HomePage();
                }
              });
        },
      ),
    );
  }
}


