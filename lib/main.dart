import 'package:flutter/material.dart';
import 'package:house_of_tutor/LoginScreen.dart';

void main() {
  runApp(const MyApp()); // 📍 ENTRY POINT
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      // ================= APP SETTINGS =================
      debugShowCheckedModeBanner: false,

      title: 'House of Tutor',

      theme: ThemeData(
        primarySwatch: Colors.blue, // 🎨 Styling
      ),

      // ================= START SCREEN =================
      home: const LoginScreen(), // 📍 FIRST SCREEN

    );
  }
}