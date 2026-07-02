/// Password rules aligned with Auth_Wayo register / reset (web parity).
abstract final class PasswordRequirements {
  static bool hasMinLength(String password) => password.length >= 8;

  static bool hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);

  static bool hasLowercase(String password) => RegExp(r'[a-z]').hasMatch(password);

  static bool hasNumber(String password) => RegExp(r'\d').hasMatch(password);

  static bool hasSymbol(String password) =>
      RegExp(r'[^a-zA-Z0-9]').hasMatch(password);

  static bool allMet(String password) =>
      hasMinLength(password) &&
      hasUppercase(password) &&
      hasLowercase(password) &&
      hasNumber(password) &&
      hasSymbol(password);

  /// Same heuristic as Auth_Wayo `password-strength.js` without zxcvbn.
  static int score(String password) {
    if (password.isEmpty) return 0;
    var s = 0;
    if (hasMinLength(password)) s++;
    if (hasUppercase(password) && hasLowercase(password)) s++;
    if (hasNumber(password)) s++;
    if (hasSymbol(password)) s++;
    return (s - 1).clamp(0, 4);
  }
}
