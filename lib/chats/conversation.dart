import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:nurox_chat/components/chat_bubble.dart';
import 'package:nurox_chat/models/enum/message_type.dart';
import 'package:nurox_chat/models/message.dart';
import 'package:nurox_chat/models/user.dart';
import 'package:nurox_chat/pages/profile.dart';
import 'package:nurox_chat/utils/firebase.dart';
import 'package:nurox_chat/view_models/conversation/conversation_view_model.dart';
import 'package:nurox_chat/view_models/user/user_view_model.dart';
import 'package:nurox_chat/widgets/indicators.dart';
import 'package:timeago/timeago.dart' as timeago;

class Conversation extends StatefulWidget {
  final String userId;
  final String chatId;

  const Conversation({super.key, required this.userId, required this.chatId});

  @override
  _ConversationState createState() => _ConversationState();
}

class _ConversationState extends State<Conversation> {
  FocusNode focusNode = FocusNode();
  ScrollController scrollController = ScrollController();
  TextEditingController messageController = TextEditingController();
  bool isFirst = false;
  String? chatId;

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to ensure context is available and avoid the listener calling setTyping before build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // We use listen: false here since we only update state
      final viewModel = Provider.of<UserViewModel>(context, listen: false);
      viewModel.setUser();
    });

    scrollController.addListener(() {
      focusNode.unfocus();
    });

    if (widget.chatId == 'newChat') {
      isFirst = true;
      chatId =
          null; // Set initial chatId to null until the first message is sent
    } else {
      chatId = widget.chatId;
    }

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setTyping(messageController.text.isNotEmpty);
      } else {
        setTyping(false);
      }
    });

    messageController.addListener(() {
      setTyping(messageController.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    scrollController.dispose();
    messageController.dispose();
    super.dispose();
  }

  // FIX 1: Corrected setTyping to use appropriate Provider access
  setTyping(bool typing) {
    // Only proceed if context allows access (i.e., not during disposal)
    if (!mounted || chatId == null) return;

    // Use context.read for non-listening access
    final user = context.read<UserViewModel>().user;
    final convViewModel = context.read<ConversationViewModel>();

    if (user != null) {
      convViewModel.setUserTyping(widget.chatId, user, typing);
    }
  }

  // FIX 2: Corrected sendMessage logic
  sendMessage(ConversationViewModel viewModel, UserModel? user,
      {bool isImage = false, int? imageType}) async {
    // Crucial null check for the sender
    if (user == null) {
      print('Sender user is null, cannot send message.');
      return;
    }

    String? msgContent;

    if (isImage) {
      // Assuming pickImage returns the download URL or null on failure
      msgContent = await viewModel.pickImage(
        source: imageType!,
        context: context,
        chatId: widget.chatId,
      );
    } else {
      msgContent = messageController.text.trim();
      messageController.clear();
      // Ensure the keyboard is still hidden after clearing the text if needed
      focusNode.unfocus();
    }

    // Only proceed if there is content to send
    if (msgContent == null || msgContent.isEmpty) return;

    // Build the Message object
    Message message = Message(
      content: msgContent,
      senderUid: user.id,
      type: isImage ? MessageType.IMAGE : MessageType.TEXT,
      time: Timestamp.now(),
    );

    if (isFirst) {
      // --- Handle First Message ---
      print("Sending FIRST message...");

      // Send the first message and get the new chatId
      String newChatId =
          await viewModel.sendFirstMessage(widget.userId, message);

      setState(() {
        isFirst = false;
        chatId = newChatId; // Update local chatId
      });

      // Update Firebase chatRef with users map and set reads/typing maps
      // The `getUser` function returns a concatenated string ID,
      // which seems incorrect for storing a list of users,
      // but let's assume it's meant to store the user IDs themselves as a List.
      // If the intent is to store a list of user IDs:
      chatRef.doc(newChatId).set({
        "users": [firebaseAuth.currentUser!.uid, widget.userId],
        "lastTextTime": Timestamp.now(), // Added this for sorting in Chats view
        "reads": {}, // Initialize reads map
        "typing": {}, // Initialize typing map
      }, SetOptions(merge: true));

      // After the first message successfully creates the chat document,
      // the existing sendMessage method should be called to add the message
      // to the new 'messages' subcollection.
      // NOTE: sendFirstMessage might already handle this, but based on your
      // original code structure, you seem to call it twice. Let's trust
      // `sendFirstMessage` handles the initial message document creation and
      // subcollection creation, but we explicitly set the chat document here.
    } else if (chatId != null) {
      // --- Handle Subsequent Messages ---
      viewModel.sendMessage(chatId!, message);
    }

    // Scroll to the bottom after sending a message
    scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIX 3: Fetch the current user once using context.watch for necessary rebuilds,
    // or context.read if only the UID is needed, but we need the UserModel here.
    final userViewModel = Provider.of<UserViewModel>(context);
    userViewModel.setUser();
    final UserModel? currentUser = userViewModel.user;

    // FIX 4: Handle the case where the current user is not yet loaded
    if (currentUser == null) {
      return Scaffold(body: Center(child: circularProgress(context)));
    }

    return Consumer<ConversationViewModel>(
      builder: (BuildContext context, viewModel, Widget? child) {
        return Scaffold(
          key: viewModel.scaffoldKey,
          appBar: AppBar(
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.keyboard_backspace),
            ),
            elevation: 0.0,
            titleSpacing: 0,
            title: buildUserName(
                currentUser), // Pass current user for profile navigation
          ),
          body: Column(
            children: [
              Flexible(
                child: StreamBuilder<QuerySnapshot>(
                  // FIX 5: Use the resolved chatId for the stream
                  stream: (chatId != null) ? messageListStream(chatId!) : null,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("Say Hello!"));
                    }

                    // FIX 6: Use reversed.toList() or map directly to avoid performance hit and redundancy
                    final messages = snapshot.data!.docs;

                    // Call setReadCount on every data update
                    viewModel.setReadCount(
                        widget.chatId, currentUser, messages.length);

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      itemCount: messages.length,
                      reverse: true, // Show newest messages at the bottom
                      itemBuilder: (BuildContext context, int index) {
                        // FIX 7: Use messages[index] directly since ListView.builder is reversed
                        final messageDoc = messages[index];

                        // FIX 8: Correctly cast the data
                        final messageData =
                            messageDoc.data() as Map<String, dynamic>?;

                        if (messageData == null) return const SizedBox.shrink();

                        Message message = Message.fromJson(messageData);

                        // FIX 9: Color logic is handled by ChatBubbleWidget,
                        // just ensure isMe is correct
                        return ChatBubbleWidget(
                          message: message.content ?? '',
                          time: message.time!,
                          isMe: message.senderUid == currentUser.id,
                          type: message.type ?? MessageType.TEXT,
                        );
                      },
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: BottomAppBar(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 10.0,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.photo_on_rectangle,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          onPressed: () =>
                              showPhotoOptions(viewModel, currentUser),
                        ),
                        Flexible(
                          child: TextField(
                            controller: messageController,
                            focusNode: focusNode,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontSize: 15.0,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleLarge!
                                      .color,
                                ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(10.0),
                              enabledBorder: InputBorder.none,
                              border: InputBorder.none,
                              hintText: "Type your message",
                              hintStyle: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .color,
                              ),
                            ),
                            maxLines: null,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Ionicons.send,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          onPressed: () {
                            if (messageController.text.trim().isNotEmpty) {
                              // FIX 10: Ensure you pass the current user model
                              sendMessage(viewModel, currentUser);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // FIX 11: Corrected StreamBuilder and added type safety
  Widget buildUserName(UserModel currentUser) {
    return StreamBuilder<DocumentSnapshot>(
      stream: usersRef.doc(widget.userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final documentSnapshot = snapshot.data!;
          final recipientUser = UserModel.fromJson(
            documentSnapshot.data() as Map<String, dynamic>,
          );

          final typingData = (documentSnapshot.data() as Map?)?['typing'] ?? {};
          final isTyping = typingData[widget.userId] == true;

          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => Profile(profileId: recipientUser.id!),
                ),
              );
            },
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                  child: Hero(
                    tag: recipientUser.email ?? 'default_tag',
                    child: recipientUser.photoUrl!.isEmpty
                        ? CircleAvatar(
                            radius: 20.0, // Reduced size for app bar
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            child: Center(
                              child: Text(
                                recipientUser.username![0].toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 20.0,
                            backgroundColor: Colors.transparent,
                            backgroundImage:
                                AssetImage(recipientUser.photoUrl!),
                          ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        recipientUser.username ?? 'User',
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.0,
                                ),
                      ),
                      const SizedBox(height: 5.0),
                      Text(
                        _buildOnlineText(recipientUser, isTyping),
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 11,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return const Center(child: Text("Loading..."));
        }
      },
    );
  }

  // Helper function for status text
  String _buildOnlineText(UserModel user, bool typing) {
    if (typing) {
      return "typing...";
    } else if (user.isOnline == true) {
      // Explicitly check for true
      return "online";
    } else if (user.lastSeen != null) {
      return 'last seen ${timeago.format(user.lastSeen!.toDate())}';
    } else {
      return "Offline";
    }
  }

  showPhotoOptions(ConversationViewModel viewModel, var user) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10.0),
        ),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text("Camera"),
              onTap: () {
                sendMessage(viewModel, user, imageType: 0, isImage: true);
              },
            ),
            ListTile(
              title: Text("Gallery"),
              onTap: () {
                sendMessage(viewModel, user, imageType: 1, isImage: true);
              },
            ),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> messageListStream(String documentId) {
    return chatRef
        .doc(documentId)
        .collection('messages')
        .orderBy('time',
            descending:
                true) // Order descending to use reverse: true in ListView
        .snapshots();
  }
}
