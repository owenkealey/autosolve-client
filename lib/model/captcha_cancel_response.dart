import 'dart:convert';

import 'package:autosolve_client/model/captcha_token_request.dart';

class CaptchaCancelResponse {
  List<CaptchaTokenRequest> captchaTokenRequestList;

  CaptchaCancelResponse(List<CaptchaTokenRequest> requestList) {
    this.captchaTokenRequestList = requestList;
  }

  CaptchaCancelResponse.fromJson(Map<String, dynamic> json) {
    List<dynamic> requestList = json['requests'];
    List<CaptchaTokenRequest> outputList = new List();
    for (var value in requestList) {
      CaptchaTokenRequest request = CaptchaTokenRequest.fromJson(value);
      outputList.add(request);
    }
    captchaTokenRequestList = outputList;
  }

  Map<String, dynamic> toJson() {
    List<dynamic> list = new List();

    for (var value in captchaTokenRequestList) {
      String json = value.toJsonString();
      list.add(json);
    }

    return {"requests": list};
  }

  String toJsonString() {
    Map<String, dynamic> json = this.toJson();
    return jsonEncode(json);
  }
}
