import 'dart:convert';

class CaptchaTokenRequest {
  String taskId;
  String url;
  String siteKey;
  String apiKey;
  int version;
  String action;
  double minScore;
  String proxy;
  int createdAt;
  bool proxyRequired;
  String userAgent;
  String cookies;
  Map<String, dynamic> renderParameters;

  CaptchaTokenRequest(this.taskId, this.url, this.siteKey, this.version,
      {this.apiKey,
      this.action,
      this.minScore,
      this.proxy,
      this.createdAt,
      this.proxyRequired,
      this.userAgent,
      this.cookies,
      this.renderParameters});

  CaptchaTokenRequest.fromJson(Map<String, dynamic> json)
      : taskId = json['taskId'].toString(),
        url = json['url'],
        siteKey = json['siteKey'],
        apiKey = json['apiKey'],
        version = json['version'],
        action = json['action'],
        minScore = parseMinScore(json),
        proxy = json['proxy'],
        createdAt = json['createdAt'],
        proxyRequired = json['proxyRequired'],
        userAgent = json['userAgent'],
        cookies = json['cookies'],
        renderParameters = json['renderParameters'];

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'url': url,
        'siteKey': siteKey,
        'apiKey': apiKey,
        'version': version,
        'action': action,
        'minScore': minScore,
        'proxy': proxy,
        'createdAt': createdAt,
        'proxyRequired': proxyRequired,
        'userAgent': userAgent,
        'cookies': cookies,
        'renderParameters': renderParameters,
      };

  String toJsonString() {
    Map<String, dynamic> json = this.toJson();
    return jsonEncode(json);
  }

  static double parseMinScore(Map json) {
    return double.tryParse(json['minScore'].toString());
  }
}
