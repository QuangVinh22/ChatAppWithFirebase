import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatefulWidget {
  const ChatMessages({super.key});

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  void setupPushNotifications() async {
    final fcm = FirebaseMessaging.instance;
    // ask
    final notificationSetting = await fcm.requestPermission();
    final getToken = await fcm.getToken();
    fcm.subscribeToTopic('chat');
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // ask
    setupPushNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;
    // TODO: implement build
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages found.!'),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Something went wrong...!'),
          );
        }
        final loadedMessages = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 40,
            left: 13,
            right: 13,
          ),
          reverse: true,
          itemCount: loadedMessages.length,
          itemBuilder: (context, index) {
            //input ra toàn bộ đoạn chat thông qua loadedMessage.
            final chatMessage = loadedMessages[index].data();
            //check xem có tin nhắn nào kế tiếp k . Nếu vị trí nó bé hơn độ dài tổng của loaded thì nó ko tồn tại
            final nextChatMessage = index + 1 < loadedMessages.length
                // nếu nó nhỏ hơn => thì có 1 tin nhắn kế tiếp
                // cập nhật tin nhắn hiện tại lên +1 index.
                ? loadedMessages[index + 1].data()

                // nếu ko thì nó tn kế tiếp null
                : null;
            //check Id xem ai là người gửi tin nhắn đề hiển thị thông tin lên.
            final currentMassageUserId = chatMessage['userId'];
            // Nếu như tin nhắn cuối cùng mà có ( khác null) thì phải biết xem ai là người gửi tin nhắn cuối
            // Nếu có gán Id của ng chat cuối vào thông quna tin nhắn cuối trỏ tới ID.
            final nextMassageUserId =
                nextChatMessage != null ? nextChatMessage['userId'] : null;

            // Nếu như có gửi tin nhắn cuối và kế cuối thì update cho họ là người gửi tin nhắn hiện tại
            final nextUserIsSame = nextMassageUserId == currentMassageUserId;
            // nếu nextUserIsSame as current user thì style cho tin nhắn kế tiếp.
            if (nextUserIsSame) {
              return MessageBubble.next(
                  //output cái text ra

                  message: chatMessage['text'],
                  // check coi người gửi hiện tại là người đang đăng nhập vô hả
                  // nếu đúng rồi thì style của tin nhắn đổi khác
                  isMe: authenticatedUser.uid == currentMassageUserId);
            } else {
              return MessageBubble.first(
                  userImage: chatMessage['userImage'],
                  username: chatMessage['username'],
                  message: chatMessage['text'],
                  isMe: authenticatedUser.uid == currentMassageUserId);
            }
          },
        );
      },
    );
  }
}
