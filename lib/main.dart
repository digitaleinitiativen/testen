import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:testen/LocationListPage.dart';

const String baseUrl = kDebugMode
    ? 'https://thingproxy.freeboard.io/fetch/https://vorarlbergtestet.lwz-vorarlberg.at'
    : 'http://mutterschiff.at/testen/proxi.php?url=https://vorarlbergtestet.lwz-vorarlberg.at';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await TimeMachine.initialize({'rootBundle': rootBundle});
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Testen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF07758A),
      ),
      home: LocationListPage(),
    );
  }
}
