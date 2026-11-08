import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../config/gemini_config.dart';
import '../config/ui_helpers.dart';
import '../models/product_model.dart';

/// Mensaje individual en el chat con el asistente IA de Percucol.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Provider para el chatbot IA de Percucol, con soporte automático
/// multimodelo para DeepSeek, Google Gemini y Motor Experto Local.
class ChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isUsingLocalEngine = false;
  String _statusNotice = '';
  String _activeProvider = 'Local';
  GenerativeModel? _geminiModel;
  ChatSession? _geminiChat;
  List<ProductModel> _cachedProducts = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get isUsingLocalEngine => _isUsingLocalEngine;
  String get statusNotice => _statusNotice;
  String get activeProvider => _activeProvider;
  bool get hasMessages => _messages.isNotEmpty;

  /// Inicializa la sesión de chat con el catálogo
  void initChat(List<ProductModel> products) {
    _cachedProducts = products;
    _messages.clear();

    if (!GeminiConfig.isConfigured) {
      _isUsingLocalEngine = true;
      _activeProvider = 'Local';
      _statusNotice = 'Modo Local Activo (Para IA en vivo, coloca tu API Key en lib/config/gemini_config.dart)';
      _geminiChat = null;
    } else if (GeminiConfig.isDeepSeek) {
      _isUsingLocalEngine = false;
      _activeProvider = 'DeepSeek AI';
      _statusNotice = '🟢 Conectado a DeepSeek AI en vivo';
      _geminiChat = null;
    } else if (GeminiConfig.isGemini) {
      _isUsingLocalEngine = false;
      _activeProvider = 'Gemini AI';
      _statusNotice = '🟢 Conectado a Google Gemini AI en vivo';
      try {
        final catalogContext = _buildCatalogContext(products);
        _geminiModel = GenerativeModel(
          model: GeminiConfig.model,
          apiKey: GeminiConfig.apiKey.trim(),
          systemInstruction: Content.system(
            '${GeminiConfig.systemPrompt}\n\nCATÁLOGO ACTUAL DE PERCUCOL:\n$catalogContext',
          ),
        );
        _geminiChat = _geminiModel!.startChat();
      } catch (e) {
        _isUsingLocalEngine = true;
        _activeProvider = 'Local';
        _statusNotice = 'Error inicializando Gemini ($e). Usando asistente local.';
      }
    } else {
      _isUsingLocalEngine = true;
      _activeProvider = 'Local';
      _statusNotice = 'Clave no reconocida. Usando asistente local experto.';
    }

    _messages.add(ChatMessage(
      text: '¡Hola! Soy **PercuBot** 🥁, tu asistente experto de Percucol.\n\n'
          'Te puedo asesorar sobre los instrumentos de nuestro catálogo, '
          'sus especificaciones técnicas y sus **referencias de uso por grandes leyendas mundiales** '
          '(Dave Weckl, Tito Puente, Giovanni Hidalgo, Totó la Momposina, entre otros).\n\n'
          '¿Qué tipo de instrumento o ritmo estás buscando hoy?',
      isUser: false,
    ));
    notifyListeners();
  }

  String _buildCatalogContext(List<ProductModel> products) {
    if (products.isEmpty) return 'Catálogo vacío.';
    final buffer = StringBuffer();
    for (final p in products) {
      buffer.writeln(
        '- ${p.name} | Precio: ${UIHelpers.formatCOP(p.price)} | '
        'Stock: ${p.stock > 0 ? "${p.stock} unidades" : "AGOTADO"} | '
        'Descripción: ${p.description.isNotEmpty ? p.description : "Sin descripción"}',
      );
    }
    return buffer.toString();
  }

  /// Envía un mensaje y responde vía DeepSeek, Gemini o motor experto local
  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isTyping) return;

    _messages.add(ChatMessage(text: query, isUser: true));
    _isTyping = true;
    notifyListeners();

    // 1. Caso DeepSeek (claves sk-...)
    if (GeminiConfig.isDeepSeek) {
      try {
        final aiResponse = await _callDeepSeekApi(query);
        if (aiResponse != null && aiResponse.trim().isNotEmpty) {
          _messages.add(ChatMessage(text: aiResponse.trim(), isUser: false));
          _isTyping = false;
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('Error llamando a DeepSeek: $e');
      }
      // Fallback a motor local si la API externa tiene error temporal
      final fallback = _generateExpertLocalResponse(query);
      _messages.add(ChatMessage(
        text: '$fallback\n\n*(Respuesta local de respaldo)*',
        isUser: false,
      ));
    }
    // 2. Caso Google Gemini (claves AIzaSy...)
    else if (GeminiConfig.isGemini && _geminiChat != null) {
      try {
        final response = await _geminiChat!.sendMessage(Content.text(query));
        final responseText = response.text ?? 'No pude generar respuesta.';
        _messages.add(ChatMessage(text: responseText, isUser: false));
        _isTyping = false;
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Error llamando a Gemini: $e');
      }
      final fallback = _generateExpertLocalResponse(query);
      _messages.add(ChatMessage(
        text: '$fallback\n\n*(Respuesta local de respaldo)*',
        isUser: false,
      ));
    }
    // 3. Caso Asistente Experto Local (sin clave o clave inválida)
    else {
      await Future.delayed(const Duration(milliseconds: 600));
      final localResponse = _generateExpertLocalResponse(query);
      _messages.add(ChatMessage(text: localResponse, isUser: false));
    }

    _isTyping = false;
    notifyListeners();
  }

  /// Llamada directa al API de DeepSeek con historial conversacional y catálogo
  Future<String?> _callDeepSeekApi(String query) async {
    final catalogContext = _buildCatalogContext(_cachedProducts);
    final systemMessage = '${GeminiConfig.systemPrompt}\n\nCATÁLOGO ACTUAL DE PERCUCOL:\n$catalogContext';

    final messagesPayload = <Map<String, String>>[
      {'role': 'system', 'content': systemMessage},
    ];

    // Incluir mensajes previos relevantes para mantener contexto
    final recent = _messages.length > 8 ? _messages.sublist(_messages.length - 8) : _messages;
    for (final m in recent) {
      messagesPayload.add({
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      });
    }

    final url = Uri.parse(GeminiConfig.deepseekEndpoint);
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${GeminiConfig.apiKey.trim()}',
          },
          body: jsonEncode({
            'model': GeminiConfig.deepseekModel,
            'messages': messagesPayload,
            'temperature': 0.7,
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        final firstChoice = choices[0] as Map<String, dynamic>;
        final message = firstChoice['message'] as Map<String, dynamic>?;
        return message?['content'] as String?;
      }
    } else {
      debugPrint('DeepSeek HTTP Error: ${response.statusCode} - ${response.body}');
    }
    return null;
  }

  /// Motor experto local de percusión con referencias mundiales y catálogo
  String _generateExpertLocalResponse(String query) {
    final lower = query.toLowerCase();

    // 0. Saludos cordiales
    if (lower == 'hola' ||
        lower.startsWith('hola') ||
        lower.contains('buenas') ||
        lower.contains('buenos') ||
        lower.contains('saludos') ||
        lower.contains('que tal') ||
        lower.contains('qué tal') ||
        lower.contains('hey')) {
      return '¡Hola! 🥁 Qué gusto saludarte. Soy **PercuBot**, tu asesor experto en percusión de Percucol.\n\n'
          '¿En qué instrumento o ritmo estás interesado hoy? Puedo recomendarte:\n'
          '• **Baterías y Platillos** (referencias de Dave Weckl, Neil Peart)\n'
          '• **Percusión Latina & Salsa** (Congas y Timbales estilo Tito Puente y Giovanni Hidalgo)\n'
          '• **Folclor Colombiano** (Tambor Alegre, Llamador y Maracas tradicionales)\n'
          '• **Cajones Flamencos/Acústicos y Shakers**\n\n'
          '¡Dime qué buscas o tu presupuesto y te daré la mejor recomendación!';
    }

    // 1. Baterías y platillos
    if (lower.contains('bater') || lower.contains('drum') || lower.contains('dw')) {
      final drum = _findProduct(['dw', 'batería', 'collector']);
      return '🥁 **Recomendación de Batería:**\n\n'
          'En nuestro catálogo destacamos la **${drum?.name ?? "Batería DW Collector's Series Maple"}** '
          '(${drum != null ? UIHelpers.formatCOP(drum.price) : "\$18.500.000 COP"}).\n\n'
          '🌍 **Referencia Mundial:**\n'
          'DW (Drum Workshop) es el estándar dorado de la percusión acústica global. '
          'Artistas legendarios como **Neil Peart (Rush)**, **Chad Smith (Red Hot Chili Peppers)** '
          'y **Terry Bozzio** han construido su sonido sobre cascos de maple DW por su resonancia cálida, '
          'ataque preciso y durabilidad en giras de estadio.\n\n'
          '${drum != null && drum.stock > 0 ? "✅ En Stock: ${drum.stock} unidades listas para despacho." : "⚠️ Estado: Consultar disponibilidad."}';
    }

    // 2. Platillos / Sabian
    if (lower.contains('platill') || lower.contains('sabian') || lower.contains('crash') || lower.contains('cymbal')) {
      final cymbal = _findProduct(['sabian', 'hhx', 'platillo']);
      return '✨ **Platillos de Alta Gama:**\n\n'
          'Te recomendamos el **${cymbal?.name ?? "Platillo Crash Sabian HHX Evolution 18\" O-Zone"}** '
          '(${cymbal != null ? UIHelpers.formatCOP(cymbal.price) : "\$1.850.000 COP"}).\n\n'
          '🌍 **Referencia Mundial:**\n'
          'La línea HHX Evolution fue desarrollada mano a mano con el virtuoso **Dave Weckl** (Chick Corea Elektric Band). '
          'Las perforaciones O-Zone ofrecen una respuesta explosiva y un sustain oscuro y cortante que no satura el micrófono en vivo ni en grabación de estudio.';
    }

    // 3. Congas y Percusión Latina
    if (lower.contains('conga') || lower.contains('lp') || lower.contains('latin') || lower.contains('tumbadora')) {
      final conga = _findProduct(['conga', 'lp classic', 'roble']);
      return '🪘 **Percusión Latina & Salsa:**\n\n'
          'Te sugiero el **${conga?.name ?? "Set de Congas LP Classic Madera de Roble"}** '
          '(${conga != null ? UIHelpers.formatCOP(conga.price) : "\$3.450.000 COP"}).\n\n'
          '🌍 **Referencia Mundial:**\n'
          'Latin Percussion (LP) es la marca que definió la salsa y el jazz latino en Nueva York. '
          'Maestros como **Giovanni Hidalgo**, **Mongo Santamaría**, **Candido Camero** y **Pedrito Martínez** '
          'han consagrado este modelo con aros Comfort Curve por su timbre redondo y protección de manos.';
    }

    // 4. Timbales
    if (lower.contains('timbal') || lower.contains('tito') || lower.contains('puente')) {
      final timbal = _findProduct(['timbal', 'tito puente']);
      return '👑 **Los Timbales del Rey:**\n\n'
          'Disponemos del modelo signature **${timbal?.name ?? "Timbales Tito Puente Signature 14\" & 15\" Latón Dorado"}**.\n\n'
          '🌍 **Referencia Mundial:**\n'
          'Bautizados en honor al legendario **Tito Puente ("El Rey del Timbal")**, '
          'este instrumento con cascos de latón macizo es el preferido en orquestas como la Spanish Harlem Orchestra '
          'y de percusionistas como **Orestes Vilató** y **Changuito** por su cascada brillante y volumen penetrante.';
    }

    // 5. Folclor Colombiano (Alegre, Llamador, Tambora)
    if (lower.contains('folclor') || lower.contains('alegre') || lower.contains('llamador') ||
        lower.contains('tambor') || lower.contains('cumbia') || lower.contains('colombia')) {
      final alegre = _findProduct(['alegre', 'costeño', 'ceiba']);
      final llamador = _findProduct(['llamador', 'venado']);
      return '🇨🇴 **Percusión Tradicional Colombiana:**\n\n'
          'Para ritmos de Cumbia, Bullerengue y Mapalé, te recomendamos:\n'
          '1. **${alegre?.name ?? "Tambor Alegre Costeño 24\""}** (${alegre != null ? UIHelpers.formatCOP(alegre.price) : "\$480.000 COP"})\n'
          '2. **${llamador?.name ?? "Tambor Llamador Colombiano"}** (${llamador != null ? UIHelpers.formatCOP(llamador.price) : "\$310.000 COP"})\n\n'
          '🌍 **Referencia y Tradición:**\n'
          'Construidos por luthiers de San Pelayo y las riberas del Río Magdalena usando madera de ceiba y cuero de chivo curado al sol. '
          'Es el sonido patrimonial inmortalizado por **Totó la Momposina**, **Petrona Martínez** y **Los Gaiteros de San Jacinto**, '
          'ganadores del Grammy Latino.';
    }

    // 6. Cajón Flamenco / Afroperuano
    if (lower.contains('cajon') || lower.contains('cajón') || lower.contains('flamenc') || lower.contains('acústic')) {
      final cajon = _findProduct(['cajón', 'cajon', 'matador']);
      return '📦 **Cajón Percusivo:**\n\n'
          'El instrumento acústico más versátil de nuestro catálogo es el **${cajon?.name ?? "Cajón Flamenco LP Matador Dark Brown"}** '
          '(${cajon != null ? UIHelpers.formatCOP(cajon.price) : "\$690.000 COP"}).\n\n'
          '🌍 **Referencia Mundial:**\n'
          'Popularizado mundialmente por **Paco de Lucía** y su percusionista **Rubem Dantas** tras descubrirlo en Perú en 1977. '
          'Hoy en día es indispensable en pop, flamenco, funk acústico y sesiones unplugged de artistas como MTV Unplugged y Tiny Desk.';
    }

    // 7. Maracas y percusión menor
    if (lower.contains('maraca') || lower.contains('shaker') || lower.contains('llaner') || lower.contains('menor')) {
      final maraca = _findProduct(['maraca', 'shaker', 'llanera']);
      return '🌾 **Percusión Menor & Shakers:**\n\n'
          'Destacamos el **${maraca?.name ?? "Juego de Maracas Llaneras de Capacho Especial"}** '
          '(${maraca != null ? UIHelpers.formatCOP(maraca.price) : "\$135.000 COP"}).\n\n'
          '🌍 **Referencia Mundial:**\n'
          'Las maracas de capacho son el motor rítmico del Joropo colombo-venezolano. '
          'Virtuosos internacionales como **Manuel Rangel** han demostrado la complejidad sinfónica '
          'de este instrumento en los teatros más prestigiosos del mundo.';
    }

    // 8. Búsqueda por presupuesto o precio
    if (lower.contains('precio') || lower.contains('costo') || lower.contains('barato') ||
        lower.contains('presupuesto') || lower.contains('cuanto') || lower.contains('cuánto')) {
      final inStockList = _cachedProducts.where((p) => p.hasStock).toList()
        ..sort((a, b) => a.price.compareTo(b.price));

      if (inStockList.isNotEmpty) {
        final cheapest = inStockList.first;
        final mid = inStockList[inStockList.length ~/ 2];
        return '💰 **Opciones según presupuesto:**\n\n'
            '• **Económica y accesible:** ${cheapest.name} por solo **${UIHelpers.formatCOP(cheapest.price)}**.\n'
            '• **Gama intermedia profesional:** ${mid.name} por **${UIHelpers.formatCOP(mid.price)}**.\n\n'
            'Todos nuestros instrumentos incluyen garantía directa y envío asegurado en Colombia.';
      }
    }

    // Respuesta general inteligente
    final available = _cachedProducts.where((p) => p.hasStock).take(3).toList();
    final buffer = StringBuffer();
    buffer.writeln('🎵 **Opciones destacadas en Percucol:**\n');
    for (final p in available) {
      buffer.writeln('• **${p.name}** — ${UIHelpers.formatCOP(p.price)} (Stock: ${p.stock})');
    }
    buffer.writeln('\nPuedes preguntarme por:');
    buffer.writeln('- *Baterías para estudio o directos*');
    buffer.writeln('- *Congas, timbales y percusión latina*');
    buffer.writeln('- *Tambores folclóricos colombianos (alegre, llamador, tambora)*');
    buffer.writeln('- *Cajones acústicos para acompañamiento*');
    return buffer.toString();
  }

  ProductModel? _findProduct(List<String> keywords) {
    for (final p in _cachedProducts) {
      final nameLower = p.name.toLowerCase();
      final descLower = p.description.toLowerCase();
      for (final kw in keywords) {
        if (nameLower.contains(kw) || descLower.contains(kw)) {
          return p;
        }
      }
    }
    return null;
  }

  void clearChat(List<ProductModel> products) {
    _messages.clear();
    _geminiChat = null;
    initChat(products);
  }
}


