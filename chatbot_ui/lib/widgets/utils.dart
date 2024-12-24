
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/colors.dart';

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
          duration: const Duration(milliseconds: 500),
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
