import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
  }

  void _submitMessage() async {
    final enteredMessage = _messageController.text;

    if (enteredMessage.trim().isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus(); //Remove the opened keyboad and something.

    _messageController.clear();

    // send to the firebase
    final user = FirebaseAuth.instance.currentUser!;

    final userData = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    // print(userData.data()!["imgUrl"]);
    FirebaseFirestore.instance.collection("chat").add({
      "text": enteredMessage,
      "CreatedAt": Timestamp.now(),
      "userId": user.uid,
      "userName": userData.data()!["userName"],
      "userImage": userData.data()!["imgUrl"]
    });
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
            textCapitalization: TextCapitalization.sentences,
            autocorrect: true,
            enableSuggestions: true,
            decoration: const InputDecoration(labelText: "send a message..."),
          )),
          IconButton(onPressed: _submitMessage, icon: const Icon(Icons.send))
        ],
      ),
    );
  }
}
