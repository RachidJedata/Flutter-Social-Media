import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nurox_chat/components/chat_item.dart';
import 'package:nurox_chat/models/message.dart';
import 'package:nurox_chat/utils/firebase.dart';
import 'package:nurox_chat/widgets/indicators.dart';

class Chats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.keyboard_backspace),
        ),
        title: Text("Chats"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: userChatsStream('${firebaseAuth.currentUser!.uid}'),
        builder: (context, snapshot) {
          // print('here is my user ' + firebaseAuth.currentUser!.uid);
          // print('here is my data ' + snapshot.data.toString());
          if (snapshot.connectionState != ConnectionState.waiting) {
            if (!snapshot.hasData) {
              return Center(child: Text('No Chats'));
            }
            List chatList = snapshot.data!.docs;
            if (chatList.isNotEmpty) {
              return ListView.separated(
                itemCount: chatList.length,
                itemBuilder: (BuildContext context, int index) {
                  DocumentSnapshot chatListSnapshot = chatList[index];
                  return StreamBuilder<QuerySnapshot>(
                    stream: messageListStream(chatListSnapshot.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        List messages = snapshot.data!.docs;
                        Message message = Message.fromJson(
                          messages.first.data(),
                        );
                        List users = chatListSnapshot.get('users');
                        // remove the current user's id from the Users
                        // list so we can get the second user's id
                        users.remove('${firebaseAuth.currentUser!.uid}');
                        String recipient = users[0];
                        return ChatItem(
                          userId: recipient,
                          messageCount: messages.length,
                          msg: message.content!,
                          time: message.time!,
                          chatId: chatListSnapshot.id,
                          type: message.type!,
                          currentUserId: firebaseAuth.currentUser!.uid,
                        );
                      } else {
                        return SizedBox();
                      }
                    },
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      height: 0.5,
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: Divider(),
                    ),
                  );
                },
              );
            } else {
              return Center(child: Text('No Chats'));
            }
          } else {
            return Center(child: circularProgress(context));
          }
        },
      ),
    );
  }

  Stream<QuerySnapshot> userChatsStream(String uid) {
    return chatRef
        .where('users', arrayContains: '$uid')
        .orderBy('lastTextTime', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> messageListStream(String documentId) {
    return chatRef
        .doc(documentId)
        .collection('messages')
        .orderBy('time', descending: true)
        .snapshots();
  }
}
