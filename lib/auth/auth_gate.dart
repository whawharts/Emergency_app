// Auth Gate
/*
  This widget checks the authentication state of the user.
  If the user is authenticated, it navigates to the HomePage.
  If not, it navigates to the LoginPage.

  unauthenticated -> LoginPage
  authenticated -> HomePage
*/

import 'package:flutter/material.dart';
import 'package:my_app/emergency_VOICE_System/login_user.dart';
import 'package:my_app/emergency_VOICE_System/emergency_menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget{
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    //listen to auth state changes

    

    //Build appropriate page based on auth state

    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context,snapshot){
        if (snapshot.connectionState == ConnectionState.waiting){
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        //check if there is a valid session currently
        final session = snapshot.hasData ? snapshot.data!.session : null;  
        if (session != null){
          return const EmergencyMenuPage();
        }else{
          return const LoginPage();
        }


      },
    );
  }
}
