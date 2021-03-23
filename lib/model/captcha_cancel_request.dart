import 'dart:convert';

class CaptchaCancelRequest {
  String taskId;
  String apiKey;
  bool responseRequired;

  CaptchaCancelRequest(this.taskId, this.apiKey, this.responseRequired);

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'apiKey': apiKey,
        'responseRequired': responseRequired
      };

  Map<String, dynamic> toJsonCancelAll() => {'taskId': taskId};

  String toJsonString() {
    Map<String, dynamic> json = this.toJson();
    return jsonEncode(json);
  }

  String toJsonStringCancelAll() {
    Map<String, dynamic> json = this.toJsonCancelAll();
    return jsonEncode(json);
  }
}
