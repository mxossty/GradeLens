import 'package:flutter/material.dart';
import 'package:gradelens_new/screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(

    url: 'https://aqaxwnoiunanlnowruxz.supabase.co',

    anonKey: 'sb_publishable_gvxchAySpdPDyQu-UPRa_g_wGlAbYcJ',

  );

  runApp(const GradeLensApp());
}

class GradeLensApp extends StatelessWidget {
  const GradeLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grade Lens',
      home: LoginScreen(), //remember to change :)
    );
  }
}