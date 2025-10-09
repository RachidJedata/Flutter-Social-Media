import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nurox_chat/models/enum/message_type.dart';

//Convertir un JSON vers une Class avec des attributs
class Message {
  String? content;
  String? senderUid;
  String? messageId;
  MessageType? type;
  Timestamp? time;

  Message({this.content, this.senderUid, this.messageId, this.type, this.time});

  Message.fromJson(Map<String, dynamic> json) {
    content = json['content'];
    senderUid = json['senderUid'];
    messageId = json['messageId'];
    if (json['type'] == 'text') {
      type = MessageType.TEXT;
    } else {
      type = MessageType.IMAGE;
    }
    time = json['time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['content'] = this.content;
    data['senderUid'] = this.senderUid;
    data['messageId'] = this.messageId;
    if (this.type == MessageType.TEXT) {
      data['type'] = 'text';
    } else {
      data['type'] = 'image';
    }
    data['time'] = this.time;
    return data;
  }
}
