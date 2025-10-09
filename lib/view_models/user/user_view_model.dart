import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:nurox_chat/models/user.dart';
import 'package:nurox_chat/screens/view_image.dart';
import 'package:nurox_chat/utils/firebase.dart';

class UserViewModel extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  FirebaseAuth auth = FirebaseAuth.instance;

  setUser() async {
    DocumentSnapshot doc = await usersRef.doc(currentUserId()).get();
    _user = UserModel.fromJson(doc.data() as Map<String, dynamic>);

    notifyListeners();
  }
}
