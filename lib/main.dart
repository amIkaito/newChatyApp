
import 'package:chat_2/posts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'my_page.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp( // これが Firebase の初期化処理です。
      options: DefaultFirebaseOptions.android,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null){
      return MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const SignInPage(),
      );
    } else {
      return const MaterialApp(
        home: ChatPage(),
      );
    }
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  Future<void> signInWithGoogle() async {
    // GoogleSignIn をして得られた情報を Firebase と関連づけることをやっています。
    final googleUser = await GoogleSignIn(scopes: ['profile', 'email']).signIn();

    final googleAuth = await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoogleSignIn'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('GoogleSignIn'),
          onPressed: () async {
            await signInWithGoogle();
            if(mounted){
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context){
                  return const ChatPage();
                }), (route) => false,
              );
            }
          },
        ),
      ),
    );
  }
}

final postsReference = FirebaseFirestore.instance.collection('posts').withConverter<Post>(
    fromFirestore: (documentSnapshot, _) {
      return Post.fromFirestore(documentSnapshot);
},
    toFirestore: (data,_) {
      return data.toMap();
    }
);

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チャット'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: (){
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context){
    return const MyPage();
    },
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage:
                NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Post>>(
              stream: postsReference.orderBy('createdAt').snapshots(),
              builder: (context, snapshot) {
                final posts = snapshot.data?.docs ??[];
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index){
                  final post = posts[index].data();
                  return Text(post.text);
                  },
                );
              }),
            ),
            TextFormField(
              onFieldSubmitted: (text){
                final newDocumentReference = postsReference.doc();

                final user = FirebaseAuth.instance.currentUser!;
                final newPost = Post(
                  text: text,
                  createdAt: Timestamp.now(),
                  posterName: user.displayName!,
                  posterImageUrl: user.photoURL!,
                  posterId: user.uid,
                  reference: postsReference.doc(),
                );

                newDocumentReference.set(newPost);
              },
            ),
          ],
        ),
      ),
    );
  }
}
