import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'screens/home_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  //Initialize FFI database factory 
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            textStyle: TextStyle(fontSize: 18),
          ),
        ),
      ),
      home: HomeScreen(),
    );
  }
}
