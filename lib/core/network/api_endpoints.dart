class ApiEndpoints {
  // Configuración base (Para ambiente local en emulador Android = 10.0.2.2, para web/iOS = localhost)
  // TODO: Mover la baseUrl a variables de entorno (.env) en un futuro cercano.
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // ==========================================
  // USUARIOS (Auth)
  // ==========================================
  static const String signup = '/signup';
  static const String login = '/login';
  static const String verifyOtp = '/verify-otp';
  static const String profile = '/profile';
  static const String resetPassword = '/reset-password';
  static const String searchUsers = '/users';
  static const String tokenRefresh = '/token/refresh';

  // ==========================================
  // DICCIONARIO
  // ==========================================
  static const String getWord = '/get_word';
  static const String getAllWords = '/get_all_words';
  static const String getSign = '/get_sign';
  static const String getAllSigns = '/get_all_signs';
  static const String createSign = '/create_sign';

  // ==========================================
  // REPRESENTACIONES
  // ==========================================
  static const String getRepresentation = '/get_representation';
  static const String getAllRepresentations = '/get_all_representations';
  static const String createRepresentation = '/create_representation';
}
