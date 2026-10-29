import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/colors.dart';
import '../models/chat_message.dart';

import '../services/ai_service.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hello! I'm your Sabcargo Assistant. I'm powered by AI and ready to help. How can I assist you?",
      timestamp: DateTime.now(),
      isUser: false,
    ),
  ];
  bool _isTyping = false;

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        timestamp: DateTime.now(),
        isUser: true,
      ));
      _controller.clear();
      _isTyping = true;
    });

    // Real-Time AI Response via Gemini
    GenerativeAIService.getChatResponse(text).then((response) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            timestamp: DateTime.now(),
            isUser: false,
          ));
          _isTyping = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sabcargo Support',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Always Online',
                  style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return FadeInLeft(
                    duration: const Duration(milliseconds: 300),
                    child: _buildTypingIndicator(),
                  );
                }
                final message = _messages[index];
                return _buildChatBubble(message);
              },
            ),
          ),
          _buildQuickReplies(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: message.isUser ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                bottomRight: Radius.circular(message.isUser ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Assistant is typing", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (i) => Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    final replies = [
      "Track My Order",
      "Shipping Rates",
      "Routes to Pakistan",
      "Routes to Bangladesh",
      "Office Locations in Riyadh",
      "Prohibited Items",
    ];
    return Container(
      height: 46,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: replies.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ActionChip(
              label: Text(replies[index]),
              labelStyle: const TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => _sendMessage(replies[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: const CircleAvatar(
              backgroundColor: AppColors.orange,
              radius: 24,
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
