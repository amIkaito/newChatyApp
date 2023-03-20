
import 'package:chat_2/posts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
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
        title: const Text('Login'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Login'),
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
  final controller = TextEditingController();
 @override
 void dispose(){
   super.dispose();
   controller.dispose();
 }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
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
                    return PostWidget(post: post);
                    },
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'テキスト',
                    fillColor: Colors.amber[100],
                    filled: true,
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber,width: 1,),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber,width: 2,),
                    ),
                  ),
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
                    controller.clear();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostWidget extends StatelessWidget {
  const PostWidget({
    super.key,
    required this.post,
  });

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(post.posterImageUrl),
          ),
          const SizedBox(width: 4,),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(post.posterName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    ),
                    Text( DateFormat('dd HH:mm').format(post.createdAt.toDate())),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: FirebaseAuth.instance.currentUser!.uid == post.posterId ? Colors.amber[100] : Colors.blue[100],
                          ),
                          child: Text(post.text),
                      ),
                    ),
                    if (FirebaseAuth.instance.currentUser!.uid == post.posterId)
                    SizedBox(
                      width: 96,
                      child: Row(
                        children: [
                          IconButton(
                              onPressed: (){
                                post.reference.delete();
                              },
                              icon: Icon(Icons.delete)
                          ),
                          IconButton(
                              onPressed: (){
                               showDialog(
                                context: context, builder: (context){
                                  return AlertDialog(
                                  title: Text('編集する'),
                                    content: TextFormField(
                                      initialValue: post.text,
                                      autofocus: true,
                                      onFieldSubmitted: (newText){
                                        post.reference.update(
                                          {
                                            'text': newText,
                                        },
                                        );
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    );
                                   },
                                  );
                               },
                              icon: const Icon(Icons.edit)
                           ),
                        ],
                      ),
                    )
                    else
                      const SizedBox(
                        width: 96,
                      )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
