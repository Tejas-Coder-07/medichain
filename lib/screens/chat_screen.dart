import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  String _selectedLanguage = 'english';

  final Map<String, String> _languages = {
    'english': '🇬🇧 English',
    'kannada': '🇮🇳 ಕನ್ನಡ',
    'hindi': '🇮🇳 हिंदी',
    'telugu': '🇮🇳 తెలుగు',
  };

  final Map<String, String> _langCodes = {
    'english': 'en_IN',
    'kannada': 'kn_IN',
    'hindi': 'hi_IN',
    'telugu': 'te_IN',
  };

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'bot',
      'text': 'Namaste! 🙏 I am MediChain, your AI health assistant. Please describe your symptoms and I will help you. How are you feeling today?',
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/diagnose'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'symptoms': text,
          'language': _selectedLanguage,
        }),
      );

      final data = jsonDecode(response.body);
      final reply = data['response'];

      setState(() {
        _messages.add({'role': 'bot', 'text': reply});
        _isLoading = false;
      });

      await _saveToFirestore(text, reply);
    } catch (e) {
      setState(() {
        _messages.add({'role': 'bot', 'text': 'Sorry, something went wrong. Please try again.'});
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _saveToFirestore(String userMsg, String botMsg) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .add({
      'userMessage': userMsg,
      'botResponse': botMsg,
      'timestamp': FieldValue.serverTimestamp(),
      'language': _selectedLanguage,
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    final available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        localeId: _langCodes[_selectedLanguage],
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A2E), Color(0xFF1A1A4E), Color(0xFF0D2137)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildLanguageSelector(),
              _buildEmergencyBanner(),
              Expanded(child: _buildMessages()),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Row(
        children: [
          Icon(Icons.medical_services, color: Color(0xFF00D4FF), size: 30),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MediChain AI',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'Available 24/7 • Free',
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return SizedBox(
      height: 45,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: _languages.entries.map((entry) {
          final isSelected = _selectedLanguage == entry.key;
          return GestureDetector(
            onTap: () => setState(() => _selectedLanguage = entry.key),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00D4FF) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00D4FF) : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF0A0A2E) : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber, color: Colors.redAccent, size: 16),
          SizedBox(width: 8),
          Text(
            'Emergency? Call 108 immediately.',
            style: TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingIndicator();
        }
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF0090AA)])
                  : null,
              color: isUser ? null : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: Radius.circular(isUser ? 15 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 15),
              ),
              border: isUser ? null : Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Text(
              msg['text'] ?? '',
              style: TextStyle(
                color: isUser ? const Color(0xFF0A0A2E) : Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              child: LinearProgressIndicator(color: Color(0xFF00D4FF)),
            ),
            SizedBox(width: 10),
            Text('Analyzing...', style: TextStyle(color: Colors.white60, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Describe your symptoms...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleListening,
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.redAccent : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                ),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}