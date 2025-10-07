import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:nurox_chat/components/fab_container.dart';
import 'package:nurox_chat/pages/notification.dart';
import 'package:nurox_chat/pages/profile.dart';
import 'package:nurox_chat/pages/search.dart';
import 'package:nurox_chat/pages/feeds.dart';
import 'package:nurox_chat/utils/firebase.dart';

class TabScreen extends StatefulWidget {
  @override
  _TabScreenState createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen> {
  int _page = 0;

  List pages = [
    {
      'title': 'Home',
      'icon': Ionicons.home,
      'page': Feeds(),
      'index': 0,
    },
    {
      'title': 'Search',
      'icon': Ionicons.search,
      'page': Search(),
      'index': 1,
    },
    {
      'title': 'add Post/Story',
      'icon': Ionicons.add_circle,
      'page': '',
      'index': 2,
    },
    {
      'title': 'Notification',
      'icon': CupertinoIcons.bell_solid,
      'page': Activities(),
      'index': 3,
    },
    {
      'title': 'Profile',
      'icon': CupertinoIcons.person_fill,
      'page': Profile(profileId: firebaseAuth.currentUser!.uid),
      'index': 4,
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        transitionBuilder: (
          Widget child,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: pages[_page]['page'],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 5),
            for (Map item in pages)
              if (item['index'] == 2)
                // If index is 2 (Add Post/Stroy), return the Fab widget directly as the item
                buildFab()
              else if (item['index'] == 3)
                StreamBuilder<int>(
                  stream:
                      streamNumberOfNotifications(), // Use the stream function
                  builder: (context, snapshot) {
                    // 2. Extract the count. Use 0 if data isn't available or an error occurred.
                    final int notificationCount = snapshot.data ?? 0;

                    // The widget to display, regardless of the count (the icon itself)
                    final notificationIcon = Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: IconButton(
                        icon: Icon(
                          item['icon'],
                          color: item['index'] != _page
                              ? Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black
                              : Theme.of(context).colorScheme.secondary,
                          size: 25.0,
                        ),
                        onPressed: () => navigationTapped(item['index']),
                      ),
                    );

                    // 3. Conditionally build the badge if the count is greater than 0
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        notificationIcon,
                        // 4. Conditional Rendering based on the resolved Future data!
                        if (notificationCount > 0)
                          Positioned(
                            right: 0,
                            top: 5,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                // Display the resolved number, converted to String
                                notificationCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                      ],
                    );
                  },
                )
              else // Handle all other indices
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: IconButton(
                    icon: Icon(
                      item['icon'],
                      color: item['index'] != _page
                          ? Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black
                          : Theme.of(context).colorScheme.secondary,
                      size: 25.0,
                    ),
                    onPressed: () => navigationTapped(item['index']),
                  ),
                ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }

  buildFab() {
    return Container(
      height: 45.0,
      width: 45.0,
      child: FabContainer(
        icon: Ionicons.add_outline,
        mini: true,
      ),
    );
  }

  void navigationTapped(int page) {
    setState(() {
      _page = page;
    });
  }

  Stream<int> streamNumberOfNotifications() {
    return notificationRef
        .doc(firebaseAuth.currentUser!.uid)
        .collection('notifications')
        .snapshots() // Get a stream of QuerySnapshots
        .map((snapshot) {
      // Map each new snapshot event to its document count (an int)
      return snapshot.docs.length;
    });
  }
}
