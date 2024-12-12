import 'package:flutter/material.dart';
import 'package:chatbot_ui/utils/colors.dart'; // Assuming you have your colors here
import '../services/api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String chatHistory = '';  // Make sure this is properly initialized
  String stage = 'new';  // Ensure this is initialized
  List<Map<String, String>> messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Application"),
        backgroundColor: AppColors.appBarColor,
      ),
      backgroundColor: AppColors.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Chat messages display section
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  String sender = messages[index]['sender']!;
                  String message = messages[index]['message']!;
                  return ChatBubble(
                    message: message,
                    sender: sender,
                    delay: index * 300, // Staggered animation delay
                  );
                },
              ),
            ),
            // Message input section
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  // TextField for message input
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: AppColors.cardBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send Button
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: AppColors.buttonBackgroundColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    String message = _messageController.text.trim();

    if (message.isNotEmpty) {
      setState(() {
        messages.add({
          'sender': 'user',
          'message': message,
        });
        chatHistory += '\nUser: $message';
        _scrollToBottom();
        _messageController.clear();
      });
      var data = await ChatAPI().sendMessageToApi(message,chatHistory,stage);
      var apiResponse = data['text'];
      setState(() {
        chatHistory += '\nBot: $apiResponse';
        stage = data['intent']!;
        messages.add({
          'sender': 'api',
          'message': '$apiResponse',
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final String sender;
  final int delay;

  const ChatBubble({super.key, required this.message, required this.sender, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    bool isUser = sender == 'user';
    Alignment alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    Color bubbleColor = isUser ? AppColors.buttonBackgroundColor : AppColors.cardBackgroundColor;
    Color textColor = isUser ? AppColors.textColor : AppColors.secondaryTextColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Align(
        alignment: alignment,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 500), // Animation duration
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, double opacity, child) {
            return Opacity(
              opacity: opacity,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: AlwaysStoppedAnimation(opacity),
                  curve: Curves.easeOut,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8.0,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
