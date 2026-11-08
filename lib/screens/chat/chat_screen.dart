import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../providers/product_provider.dart';

/// Pantalla del Chatbot IA de Percucol (PercuBot) potenciado por Google Gemini.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final products = Provider.of<ProductProvider>(context, listen: false).products;
      Provider.of<ChatProvider>(context, listen: false).initChat(products);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _scrollToBottom();

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PercuBot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  'Asistente IA · ${chatProvider.activeProvider}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reiniciar conversación',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryGold),
            onPressed: () {
              final products = Provider.of<ProductProvider>(context, listen: false).products;
              chatProvider.clearChat(products);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Aviso informativo de modo IA
          if (chatProvider.statusNotice.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primaryGold, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      chatProvider.statusNotice,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Lista de mensajes
          Expanded(
            child: chatProvider.messages.isEmpty
                ? _LoadingWidget(isDark: isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: chatProvider.messages.length + (chatProvider.isTyping ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == chatProvider.messages.length) {
                        return const _TypingIndicator();
                      }
                      final msg = chatProvider.messages[i];
                      return _MessageBubble(
                        message: msg.text,
                        isUser: msg.isUser,
                        isDark: isDark,
                      );
                    },
                  ),
          ),

          // Sugerencias rápidas
          if (!chatProvider.isTyping && chatProvider.messages.length == 1)
            _QuickSuggestions(
              onTap: (q) async {
                _controller.text = q;
                await _sendMessage();
              },
            ),

          // Campo de texto
          _InputBar(
            controller: _controller,
            isDark: isDark,
            isLoading: chatProvider.isTyping,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ─── Burbuja de mensaje ───────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser ? AppColors.goldGradient : null,
          color: isUser
              ? null
              : (isDark ? AppColors.darkCard : AppColors.lightCardElevated),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser) ...[
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded, size: 14, color: Colors.black),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isUser
                      ? Colors.black
                      : (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Indicador "escribiendo..." ───────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                color: AppColors.primaryGold,
                backgroundColor: Colors.transparent,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'PercuBot está pensando...',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textDarkSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sugerencias rápidas ──────────────────────────────────────────────────────

class _QuickSuggestions extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _QuickSuggestions({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      '🥁 ¿Qué batería me recomiendas para principiantes?',
      '🎵 ¿Cuáles son los mejores cajones del catálogo?',
      '🌍 Artistas famosos de percusión latina',
      '🎯 ¿Qué instrumento compro con \$500.000 COP?',
    ];

    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        children: suggestions
            .map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.primaryGold.withValues(alpha: 0.1),
                    side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                    onPressed: () => onTap(s),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isDark,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Pregunta sobre instrumentos...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primaryGold,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: isLoading ? null : onSend,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  child: Icon(
                    isLoading ? Icons.hourglass_top_rounded : Icons.send_rounded,
                    color: Colors.black,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Loading ──────────────────────────────────────────────────────────────────

class _LoadingWidget extends StatelessWidget {
  final bool isDark;
  const _LoadingWidget({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 42, color: Colors.black),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: AppColors.primaryGold, strokeWidth: 2),
          const SizedBox(height: 12),
          Text(
            'Iniciando PercuBot...',
            style: TextStyle(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

