import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nurox_chat/models/message.dart';
import 'package:nurox_chat/services/chat_service.dart';

class ConversationViewModel extends ChangeNotifier {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  ChatService chatService = ChatService();
  bool uploadingImage = false;
  final picker = ImagePicker();
  File? image;

  sendMessage(String chatId, Message message) {
    chatService.sendMessage(
      message,
      chatId,
    );
  }

  Future<String> sendFirstMessage(String recipient, Message message) async {
    String newChatId = await chatService.sendFirstMessage(
      message,
      recipient,
    );

    return newChatId;
  }

  setReadCount(String chatId, var user, int count) {
    chatService.setUserRead(chatId, user, count);
  }

  setUserTyping(String chatId, var user, bool typing) {
    chatService.setUserTyping(chatId, user, typing);
  }

  pickImage({int? source, BuildContext? context, String? chatId}) async {
    PickedFile? pickedFile = source == 0
        ? await picker.getImage(
            source: ImageSource.camera,
          )
        : await picker.getImage(
            source: ImageSource.gallery,
          );

    if (pickedFile != null) {
      // Define the presets outside to keep the code clean
      final List<CropAspectRatioPreset> presets = [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ];

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        // ❌ REMOVED: aspectRatioPresets: [...]
        // This line caused the error in newer versions.

        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop image',
            toolbarColor: Theme.of(context!).appBarTheme.backgroundColor,
            toolbarWidgetColor: Theme.of(context).iconTheme.color,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,

            // ✅ CORRECTED: aspectRatioPresets is now inside AndroidUiSettings
            aspectRatioPresets: presets,
          ),

          IOSUiSettings(
            title: 'Crop image', // Added title for iOS dialog
            minimumAspectRatio: 1.0,

            // ✅ CORRECTED: aspectRatioPresets is now inside IOSUiSettings
            aspectRatioPresets: presets,
          ),
        ],
      );

      Navigator.of(context).pop();

      if (croppedFile != null) {
        uploadingImage = true;
        image = File(croppedFile.path);
        notifyListeners();
        showInSnackBar("Uploading image...", context);
        String imageUrl = await chatService.uploadImage(image!, chatId!);
        return imageUrl;
      }
    }
  }

  void showInSnackBar(String value, context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
      ),
    );
  }
}
