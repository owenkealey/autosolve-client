import 'dart:convert';

import 'captcha_token_request.dart';

class CaptchaTokenResponse {
  final String sessionId;
  final CaptchaTokenRequest request;
  final String token;
  final String taskId;
  final String apiKey;
  final int createdAt;

  CaptchaTokenResponse(this.sessionId, this.request, this.token, this.taskId,
      this.apiKey, this.createdAt);

  CaptchaTokenResponse.fromJson(Map<String, dynamic> json)
      : sessionId = json['sessionId'],
        request = CaptchaTokenRequest.fromJson(json['request']),
        token = json['token'],
        taskId = json['taskId'],
        apiKey = json['apiKey'],
        createdAt = json['createdAt'];

  Map<String, dynamic> toJson() => {
        "request": request.toJson(),
        "token": token,
        "taskId": taskId,
        "apiKey": apiKey,
        "createdAt": createdAt
      };

  String toJsonString() {
    Map<String, dynamic> json = this.toJson();
    return jsonEncode(json);
  }
}
