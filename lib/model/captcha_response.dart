import 'dart:convert';

import 'captcha_token_response.dart';

class CaptchaResponse {
  String solverName;
  CaptchaTokenResponse captchaTokenResponse;

  CaptchaResponse(this.solverName, this.captchaTokenResponse);

  Map<String, dynamic> toJson() =>
      {"solverName": solverName, "token": captchaTokenResponse.toJson()};

  String toJsonString() {
    Map<String, dynamic> json = this.toJson();
    return jsonEncode(json);
  }
}
