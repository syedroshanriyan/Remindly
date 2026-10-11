class InputSanitizer {
  /// Strips potentially dangerous script tags, html tags, control chars and null-bytes.
  static String sanitize(String input) {
    if (input.isEmpty) return input;

    // 1. Remove null-bytes and dangerous control characters (preserve tabs and newlines)
    String sanitized = input.replaceAll(RegExp(r'[\x00\x08\x0B\x0C\x0E-\x1F]'), '');

    // 2. Remove <script> tags and their contents
    sanitized = sanitized.replaceAll(
      RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false),
      '',
    );

    // 3. Remove inline javascript attributes (e.g., onload=, onclick=, href="javascript:...")
    sanitized = sanitized.replaceAll(
      RegExp(r'''\bon\w+\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]+)''', caseSensitive: false),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'javascript\s*:', caseSensitive: false),
      '',
    );

    // 4. Strip html/xml tags if embedded
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');

    return sanitized.trim();
  }
}
