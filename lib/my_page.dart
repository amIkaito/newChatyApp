import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'main.dart';

class MyPage extends StatelessWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: Text('マイページ'),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 24,),
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(
                user.photoURL!,
              ),
            ),
            Text(
              user.displayName!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 24,),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ユーザーID :${user.uid}'),
                Text('登録日 ${user.metadata.creationTime!.toString()}'),
            ],
            ),
            SizedBox(height: 24,),
            ElevatedButton(onPressed: ()async{
              await GoogleSignIn().signOut();
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context){
                return const SignInPage();
              }), (route) => false,
              );
            },
                child: Text('サインアウト'),
            )
          ],
        ),
      ),
    );
  }
}
