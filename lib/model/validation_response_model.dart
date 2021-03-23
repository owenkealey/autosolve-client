class ValidationResponse {
  final String name;
  final String accessToken;

  ValidationResponse(this.name, this.accessToken);

  factory ValidationResponse.fromJson(Map<String, dynamic> json) {
    return ValidationResponse(json['name'], json['accessToken']);
  }
}
