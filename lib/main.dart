import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // On Android the Firebase config comes from android/app/google-services.json,
  // which the Google Services Gradle plugin compiles into the app.
  await Firebase.initializeApp();
  runApp(CampusFixApp());
}
