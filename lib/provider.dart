import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//ユーザ情報の受け渡しを行うProvider
final userProvider = StateProvider((ref){
  return FirebaseAuth.instance.currentUser;
});

//エラー情報の受け渡しを行うProvider
//autoDisposeにより、自動的に値をリセットできる
final infoTextProvider = StateProvider.autoDispose((ref)=>'');

//メルアドの受け渡しを行うProvider
final emailProvider = StateProvider.autoDispose((ref)=>'');

final passwordProvider = StateProvider.autoDispose((ref)=>'');

final messageTextProvider = StateProvider.autoDispose((ref)=>'');

//リストの取得を行うProvider。
final postQueryProvider = StreamProvider((ref){
  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('date')
      .snapshots();
});