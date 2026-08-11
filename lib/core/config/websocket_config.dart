class WebSocketConfig {
  // Используем localhost, так как тестируем на реальном устройстве с ADB reverse.
  // Используем 10.0.2.2 (вместо localhost) если используем Android emulator
  // Если порт бэкенда отличается от 3000, измените его здесь.
  static const String serverUrl = 'ws://localhost:8080';
}
