import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nurox_chat/utils/firebase.dart';

class LifecycleEventHandler extends WidgetsBindingObserver {
  LifecycleEventHandler({this.currentUserId});

  final String? currentUserId;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (currentUserId == null) return;

    // Use a variable to determine the status to avoid duplicate calls
    bool isOnline;
    switch (state) {
      case AppLifecycleState.resumed:
        // User brings the app back to the foreground
        isOnline = true;
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // User minimizes or closes the app
        isOnline = false;
        break;
    }

    // Call the async method without blocking the UI thread
    updateOnlineStatus(currentUserId!, isOnline);
  }

  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    Map<String, dynamic> data = {
      'isOnline': isOnline,
    };

    if (!isOnline) {
      // Only update lastSeen when the user goes offline
      data['lastSeen'] = Timestamp.now();
    }

    try {
      await usersRef.doc(userId).update(data);
    } catch (e) {
      print("Error updating online status for $userId: $e");
    }
  }
}
