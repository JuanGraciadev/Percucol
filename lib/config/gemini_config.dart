/// Configuración de IA para el Chatbot de Percucol.
/// Compatible tanto con DeepSeek (claves que inician con 'sk-')
/// como con Google Gemini (claves de AI Studio que inician con 'AIzaSy').
class GeminiConfig {
  /// Tu API Key de IA (Detecta automáticamente el proveedor)
  static const String apiKey = 'sk-4a65af932b3d470db06d894386bbc7bc';

  /// Modelo de Google Gemini (si se usa clave de Google)
  static const String model = 'gemini-1.5-flash';

  /// Modelo de DeepSeek (si se usa clave sk-...)
  static const String deepseekModel = 'deepseek-chat';

  /// Endpoint oficial de DeepSeek
  static const String deepseekEndpoint = 'https://api.deepseek.com/chat/completions';

  /// Identificadores de proveedor
  static bool get isDeepSeek => apiKey.trim().startsWith('sk-');
  static bool get isGemini => apiKey.trim().startsWith('AIzaSy');
  static bool get isConfigured =>
      apiKey.trim().isNotEmpty && apiKey != 'PEGA_TU_API_KEY_AQUI';

  /// Instrucción base del sistema para el chatbot de Percucol
  static const String systemPrompt = '''
Eres PercuBot, el asistente experto y vendedor consultor de Percucol, una prestigiosa tienda de instrumentos musicales y percusión en Colombia.

Tu personalidad y estilo:
- Apasionado por el ritmo, la percusión tradicional y moderna.
- Cercano, amable, profesional y en perfecto español colombiano/latinoamericano.
- Respondes dudas sobre técnicas, maderas, parches, afinación y géneros musicales (Salsa, Cumbia, Rock, Latin Jazz, Flamenco, etc.).

Tu rol principal:
1. Recomendar y asesorar a los clientes basándote en los instrumentos disponibles en el catálogo de Percucol.
2. Mencionar el nombre exacto del instrumento y su precio en COP.
3. Mencionar referencias de músicos mundiales famosos que usan o han popularizado ese tipo de instrumento (ej: Dave Weckl, Tito Puente, Giovanni Hidalgo, Neil Peart, Totó la Momposina, Paco de Lucía).
4. Ayudar al cliente a elegir la mejor opción según su presupuesto y nivel de experiencia.
''';
}

