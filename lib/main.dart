import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_chat_app/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  // 初期化処理を追加
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      child: ChatApp(),
    ),
  );
}

class ChatApp extends StatelessWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatApp',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: LoginPage(),
    );
  }
}

//ログイン画面用Widget
class LoginPage extends ConsumerWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //メッセージ表示用
    String infoText = ref.watch(infoTextProvider);

    //入力したメールアドレス・パスワード
    String email = ref.watch(emailProvider);
    String password = ref.watch(passwordProvider);

    //登録・ログインボタン等の複数回タップ防止用フラグ
    bool registerFlag = false;
    bool loginFlag = false;
    bool guestLoginFlag = false;

    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 100,
                child: Text(
                  'ChatApp',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              //メールアドレス入力
              TextFormField(
                  decoration: const InputDecoration(labelText: 'メールアドレス'),
                  onChanged: (String value) {
                    //Providerから値を更新
                    ref.read(emailProvider.notifier).state = value;
                  }),
              //パスワード入力
              TextFormField(
                decoration: const InputDecoration(labelText: 'パスワード'),
                obscureText: true,
                onChanged: (String value) {
                  //Providerから値を更新
                  ref.read(passwordProvider.notifier).state = value;
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(infoText),
              ),
              SizedBox(
                width: double.infinity,
                //ユーザ登録ボタン
                child: ElevatedButton(
                  child: const Text('メールアドレスでユーザ登録'),
                  onPressed: () async {
                    if (registerFlag == true) {
                      return;
                    }
                    try {
                      registerFlag = true;
                      //メール・パスワードでユーザ登録
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final result = await auth.createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                      ref.read(userProvider.notifier).state = result.user;
                      //ユーザ登録に成功した場合
                      registerFlag = true;
                      //チャット画面に繊維＋ログイン画面を破棄
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) {
                          return ChatPage();
                        }),
                      );
                      registerFlag = false;
                    } catch (e) {
                      //Providerから値を更新
                      ref.read(infoTextProvider.notifier).state =
                          '登録に失敗しました：${e.toString()}';
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  child: const Text('メールアドレスでログイン'),
                  onPressed: () async {
                    if (loginFlag == true) {
                      return;
                    }
                    try {
                      loginFlag = true;
                      //メール/パスワードでログイン
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final result = await auth.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                      ref.read(userProvider.notifier).state = result.user;
                      //ログインに成功した場合
                      //チャット画面に遷移＋ログイン画面を破棄
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) {
                          return ChatPage();
                        }),
                      );
                      loginFlag = false;
                    } catch (e) {
                      //Providerから値を更新
                      ref.read(infoTextProvider.notifier).state =
                          'ログインに失敗しました：${e.toString()}';
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('ゲストとしてログイン'),
                  onPressed: () async {
                    if (guestLoginFlag == true) {
                      return;
                    }
                    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
                    try {
                      guestLoginFlag = true;
                      final result = await firebaseAuth.signInAnonymously();
                      ref.read(userProvider.notifier).state = result.user;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) {
                          return ChatPage();
                        }),
                      );
                      guestLoginFlag = false;
                    } catch (e) {
                      //Providerから値を更新
                      ref.read(infoTextProvider.notifier).state =
                          'ログインに失敗しました：${e.toString()}';
                    }
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

//チャット画面用Widget
class ChatPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User user = ref.watch(userProvider)!;
    final AsyncValue<QuerySnapshot> asyncPostsQuery =
        ref.watch(postQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatApp'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              //ログアウト処理
              //内部で保持しているログイン情報等が初期化される
              await FirebaseAuth.instance.signOut();
              //ログイン画面に遷移＋チャット画面を破棄
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) {
                  return const LoginPage();
                }),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.all(8.0),
            child: ref.watch(userProvider.state).state?.isAnonymous == true
                ? const Text('現在ゲストとしてログインしています。')
                : const Text('現在メールアドレスでログインしています。'),
          ),
          Expanded(
            flex: 13,
            //StreamProviderから受け取った値は .when()で状態に応じて出し分けできる
            child: asyncPostsQuery.when(
              //値が取得できた場合
              data: (QuerySnapshot query) {
                return ListView(
                  children: query.docs.map((document) {
                    return Card(
                      child: ListTile(
                        title: Text(document['text']),
                        subtitle: document['uid'] == user.uid
                            ? const Text(
                                'あなたの投稿',
                                style: TextStyle(
                                  color: Colors.deepOrangeAccent,
                                  fontSize: 12,
                                ),
                              )
                            : const Text(
                                '誰かの投稿',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                        trailing: document['uid'] == user.uid
                            ? IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  // ダイアログを表示
                                  var result = await showDialog<int>(
                                    context: context,
                                    //背景タップでダイアログを閉じられるようにする
                                    barrierDismissible: true,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('このメッセージを削除してもよろしいですか？'),
                                        content: const Text('※この操作は取り消すことができません。'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('キャンセル'),
                                            onPressed: () =>
                                                Navigator.of(context).pop(0),
                                          ),
                                          ElevatedButton(
                                            child: const Text('OK'),
                                            onPressed: () async {
                                              //投稿メッセージのドキュメントを削除
                                              await FirebaseFirestore.instance
                                                  .collection('posts')
                                                  .doc(document.id)
                                                  .delete();
                                              Navigator.of(context).pop(1);
                                            }
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  //print('dialog result: $result');
                                },
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
              //値が読み込み中の時
              loading: () {
                return const Center(
                  child: Text('読み込み中...'),
                );
              },
              //値の取得に失敗した時
              error: (e, stackTrace) {
                return Center(
                  child: Text(e.toString()),
                );
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              return const AddPostPage();
            }),
          );
        },
      ),
    );
  }
}

//投稿画面用Widget
class AddPostPage extends ConsumerWidget {
  const AddPostPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Providerから値を受け取る
    //!により、何も入っていない場合はエラーになる
    final user = ref.watch(userProvider)!;
    final messageText = ref.watch(messageTextProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('チャット投稿'),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: '投稿メッセージ'),
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                onChanged: (String value) {
                  ref.read(messageTextProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('投稿'),
                  onPressed: () async {
                    if (messageText != '') {
                      final date = DateTime.now().toLocal().toIso8601String();
                      final uid = user.uid;
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc()
                          .set({'text': messageText, 'uid': uid, 'date': date});
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  child: const Text('戻る'),
                  onPressed: () {
                    Navigator.of(context).pop();
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
