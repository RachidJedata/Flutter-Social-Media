import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nurox_chat/models/status.dart';
import 'package:nurox_chat/models/user.dart';
import 'package:nurox_chat/posts/story/status_view.dart';
import 'package:nurox_chat/utils/firebase.dart';
import 'package:nurox_chat/widgets/indicators.dart';

class StoryWidget extends StatelessWidget {
  const StoryWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Fetch the list of story documents the current user can see
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: storiesIcanSeeStream('${firebaseAuth.currentUser!.uid}'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: circularProgress(context));
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading stories: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // If no stories are available, return minimal height.
            return const SizedBox(height: 1.0);
          }

          // 1. Get all documents from the stream
          List<DocumentSnapshot> allStatusDocs = snapshot.data!.docs;

          // 2. 🚨 KEY CORRECTION: Extract and de-duplicate the 'userId' (ownerId) 🚨
          // We use a Set to automatically handle de-duplication.
          Set<String> uniqueOwnerIds = {};

          for (var doc in allStatusDocs) {
            // Safely extract the 'userId' field
            String? ownerId;
            try {
              // Note: Using doc['userId'] is often safer than doc.get('userId')
              ownerId = doc['userId'] as String?;
            } catch (_) {
              // Ignore documents that are missing the 'userId' field
            }

            if (ownerId != null) {
              uniqueOwnerIds.add(ownerId);
            }
          }

          // 3. Convert the Set back to a List for use in ListView.builder
          List<String> storyOwnerIds = uniqueOwnerIds.toList();

          // If after de-duplication we have no owners (e.g., all docs were corrupt), handle it.
          if (storyOwnerIds.isEmpty) {
            return const SizedBox(height: 1.0);
          }

          return Container(
            height: 100.0,
            padding: const EdgeInsets.only(left: 5.0, right: 5.0),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              itemCount: storyOwnerIds.length,
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                // Get the single, unique owner ID for this index
                final String storyOwnerId = storyOwnerIds[index];

                // Pass only the necessary Owner ID and an optional index (if needed for list keying)
                return _buildStatusAvatar(
                  storyOwnerId,
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Helper method to build the status avatar and user details (no change needed here)
  Widget _buildStatusAvatar(
    String storyOwner,
  ) {
    // 4. Fetch the user's details for the avatar image and username
    return StreamBuilder<DocumentSnapshot>(
      stream: usersRef.doc(storyOwner).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink(); // Hide if user data is missing
        }

        DocumentSnapshot documentSnapshot = snapshot.data!;
        UserModel user =
            UserModel.fromJson(documentSnapshot.data() as Map<String, dynamic>);

        return Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StatusScreen(
                        ownerId: storyOwner,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 2.5,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12, // Using a simple shadow
                        offset: Offset(0.0, 0.0),
                        blurRadius: 2.0,
                        spreadRadius: 0.0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: CircleAvatar(
                      radius: 30.0,
                      backgroundColor: Colors.grey,
                      backgroundImage: AssetImage(
                        user.photoUrl!,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                user.username!,
                style: const TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
        );
      },
    );
  }

  // The only stream needed for the main status list
  Stream<QuerySnapshot> storiesIcanSeeStream(String uid) {
    // Fetches documents (status entries) where the user is listed in whoCanSee
    return statusRef.where('whoCanSee', arrayContains: uid).snapshots();
  }
}
