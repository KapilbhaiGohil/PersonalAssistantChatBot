import 'package:chatbot_ui/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String labelText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Function(String) onChanged;
  final Icon icon;

  CustomTextField({
    required this.controller,
    required this.hintText,
    required this.labelText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    required this.onChanged, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: icon,
        hintStyle: const TextStyle(color: Colors.grey), // Placeholder text style
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
      ),
    );
  }
}
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final double paddingVertical;
  final double paddingHorizontal;
  final Icon icon;
  final double iconSize;  // Customizable icon size
  final EdgeInsetsGeometry? margin;  // Optional margin for custom positioning

  CustomButton({
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 7.0,
    this.paddingVertical = 10.0,
    this.paddingHorizontal = 15.0,
    required this.icon,
    this.iconSize = 20.0,  // Default icon size
    this.margin,  // Optional margin for button positioning
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,  // Optional margin
      width: double.infinity,  // Makes the button span the full width of the parent
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          padding: EdgeInsets.symmetric(
            vertical: paddingVertical,
            horizontal: paddingHorizontal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          shadowColor: Colors.black,  // Adding shadow color for better contrast
          elevation: 5,  // Adds subtle elevation to the button
        ),
        icon: Icon(
          icon.icon,
          color: AppColors.backgroundColor,  // Icon color based on text color
          size: iconSize,
        ),
        label: Text(
          text,
          style: TextStyle(
            color: AppColors.backgroundColor,  // Default white color for text
            fontSize: 16.0,
            fontWeight: FontWeight.bold,  // Bold text style for better emphasis
          ),
        ),
      ),
    );
  }
}