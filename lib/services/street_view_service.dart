class StreetViewService {
  final String apiKey;
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/streetview';
  static const int _defaultWidth = 600;
  static const int _defaultHeight = 300;
  static const int _defaultFov = 90;

  StreetViewService(this.apiKey);

  String getStreetViewImage(double latitude, double longitude, {
    int? width,
    int? height,
    int? fov,
    String? heading,
    String? pitch,
  }) {
    return '$_baseUrl?'
        'size=${width ?? _defaultWidth}x${height ?? _defaultHeight}'
        '&location=$latitude,$longitude'
        '&fov=${fov ?? _defaultFov}'
        '${heading != null ? '&heading=$heading' : ''}'
        '${pitch != null ? '&pitch=$pitch' : ''}'
        '&key=$apiKey';
  }

  String getStreetViewMetadataUrl(double latitude, double longitude) {
    return 'https://maps.googleapis.com/maps/api/streetview/metadata'
        '?location=$latitude,$longitude'
        '&key=$apiKey';
  }
}