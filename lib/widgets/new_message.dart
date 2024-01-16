import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});
  @override
  State<StatefulWidget> createState() {
    return _NewMesaage();
  }
}

class _NewMesaage extends State<NewMessage> {
  final _messageController = TextEditingController();
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final enteredMessage = _messageController.text;
    if (enteredMessage.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    _messageController.clear();

    // lấy ra ai gửi tin nhắn này
    final user = FirebaseAuth.instance.currentUser!;
    // lấy ra tên và avatar của người dùng sau khi lưu trữ lên FireStore
    // Luu ý trong thư mục user
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    //gửi tin nhắn lên firebase

    String uid = user.uid;
    if (uid == null) {
      print("NULLL RỒI DCMM");
    }
    await FirebaseFirestore.instance.collection('chat').add(
      {
        'text': enteredMessage,
        'userId': uid,
        'createdAt': Timestamp.now(),
        'userImage': userData.data()!['image_url'],
        'username': userData.data()!['username'],
      },
    );
    print(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 1, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              // viet hoa chu cai dau
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              decoration: const InputDecoration(labelText: "Send a message..."),
            ),
          ),
          IconButton(
            color: Theme.of(context).colorScheme.primary,
            onPressed: _submitMessage,
            icon: const Icon(Icons.send),
          )
        ],
      ),
    );
  }
}
