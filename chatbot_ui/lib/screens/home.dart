import 'package:flutter/material.dart';
import 'package:chatbot_ui/utils/colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api.dart';
import '../widgets/utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String chatHistory = '';
  String stage = 'new';
  List<Map<String, String>> messages = [];
  late AnimationController _menuController;
  late Animation<double> _menuAnimation;
  bool isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
      if (isMenuOpen) {
        _menuController.forward();
      } else {
        _menuController.reverse();
      }
    });
  }

  void _closeMenu() {
    if (isMenuOpen) {
      setState(() {
        isMenuOpen = false;
        _menuController.reverse();
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during sign out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeMenu,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Chat Application"),
          backgroundColor: AppColors.appBarColor,
          leading: IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _menuAnimation,
            ),
            onPressed: _toggleMenu,
          ),
        ),
        backgroundColor: AppColors.scaffoldBackgroundColor,
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
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
                          delay: index * 300,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
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
            if (isMenuOpen)
              Positioned(
                top: 0,
                left: 0,
                child: SizeTransition(
                  sizeFactor: _menuAnimation,
                  axisAlignment: -1.0,
                  child: Container(
                    color: AppColors.cardBackgroundColor,
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Log Out'),
                          onTap: () async {
                            _closeMenu();
                            await Future.delayed(const Duration(milliseconds: 200));
                            await _signOut();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    String message = _messageController.text.trim();
    String? email = FirebaseAuth.instance.currentUser?.email;

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
      var data = await ChatAPI().sendMessageToApi(message, chatHistory, stage, email!);
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