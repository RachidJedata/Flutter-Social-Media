import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ionicons/ionicons.dart';
import 'package:nurox_chat/chats/recent_chats.dart';
import 'package:nurox_chat/models/post.dart';
import 'package:nurox_chat/screens/view_image.dart';
import 'package:nurox_chat/services/chat_service.dart';
import 'package:nurox_chat/utils/constants.dart';
import 'package:nurox_chat/utils/firebase.dart';
import 'package:nurox_chat/widgets/indicators.dart';
import 'package:nurox_chat/widgets/story_widget.dart';
import 'package:nurox_chat/widgets/userpost.dart';

class Feeds extends StatefulWidget {
  @override
  _FeedsState createState() => _FeedsState();
}

class _FeedsState extends State<Feeds> with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  int page = 5;
  bool loadingMore = false;
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    scrollController.addListener(() async {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        setState(() {
          page = page + 5;
          loadingMore = true;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // print('>>>');
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            Constants.appName,
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Ionicons.chatbubble_ellipses,
                    color: Theme.of(context).primaryColor,
                    size: 30.0,
                  ),
                  StreamBuilder<int>(
                    stream: ChatService()
                        .getNumberOfUnreadMessages(currentUserId()),
                    builder: (context, AsyncSnapshot<int?> snapshot) {
                      final int messagesCount = snapshot.data ?? 0;
                      print('messagesCount $messagesCount');

                      if (messagesCount == 0) {
                        return const SizedBox();
                      }

                      return Positioned(
                        right: -1,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            messagesCount > 99 ? '99+' : '$messagesCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => Chats(),
                  ),
                );
              },
            ),
            const SizedBox(width: 20.0),
          ]),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.secondary,
        onRefresh: () =>
            postRef.orderBy('timestamp', descending: true).limit(page).get(),
        child: FutureBuilder(
          future:
              postRef.orderBy('timestamp', descending: true).limit(page).get(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasData) {
              var snap = snapshot.data;
              List docs = snap!.docs;

              // *** This is the MAIN scrollable widget. ***
              return ListView.builder(
                // Use the scrollController here for infinite scrolling logic
                controller: scrollController,

                // Add 1 for the StoryWidget at the top
                itemCount: docs.length + 1,

                itemBuilder: (context, index) {
                  // *** Handle the StoryWidget at index 0 ***
                  if (index == 0) {
                    return StoryWidget();
                  }

                  // *** Handle the Posts for index > 0 ***
                  int postIndex =
                      index - 1; // Adjust index for the list of posts
                  PostModel posts = PostModel.fromJson(docs[postIndex].data());

                  return Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: UserPost(post: posts),
                  );
                },
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              // Show loading indicator in the center while waiting
              return Center(child: circularProgress(context));
            } else {
              return Center(
                child: Text(
                  'No Feeds',
                  style: TextStyle(
                    fontSize: 26.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
