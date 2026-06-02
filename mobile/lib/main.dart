import 'package:flutter/material.dart';

import 'core/api_client.dart';

import 'presentation/auth/login_page.dart';

import 'presentation/monitoring/monitoring_page.dart';



void main() {

  runApp(const MyApp());

}



class MyApp extends StatelessWidget {

  const MyApp({super.key});



  @override

  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(

            seedColor: const Color(0xFF0052CC)),

        useMaterial3: true,

        scaffoldBackgroundColor: Colors.white,

      ),

      home: FutureBuilder<bool>(

        future: ApiClient.hasToken(),

        builder: (context, snapshot) {

          if (snapshot.connectionState != ConnectionState.done) {

            return const Scaffold(

              body: Center(child: CircularProgressIndicator()),

            );

          }

          return snapshot.data == true

              ? const MonitoringPage()

              : const LoginPage();

        },

      ),

    );

  }

}
