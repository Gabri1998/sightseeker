class PlacesException implements Exception {
  final String message;
  final int? code;

  PlacesException(this.message, {this.code});

  @override
  String toString() => 'PlacesException: $message${code != null ? ' (code $code)' : ''}';
}