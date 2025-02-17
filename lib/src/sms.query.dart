part of flutter_sms_inbox;

class SmsQuery {
  static SmsQuery? instance;
  final MethodChannel _channel;

  factory SmsQuery() {
    if (instance == null) {
      const MethodChannel methodChannel = MethodChannel(
        "plugins.jerryhchen.com/querySMS",
        JSONMethodCodec(),
      );
      instance = SmsQuery._private(methodChannel);
    }
    return instance!;
  }

  SmsQuery._private(this._channel);

  /// Wrapper to query one kind at a time
  Future<List<SmsMessage>> _querySms({
    int? start,
    int? count,
    String? address,
    int? threadId,
    SmsQueryKind kind = SmsQueryKind.inbox,
    SmsOrder? order,
  }) async {
    Map arguments = {};
    if (start != null && start >= 0) {
      arguments["start"] = start;
    }
    if (count != null && count > 0) {
      arguments["count"] = count;
    }
    if (address != null && address.isNotEmpty) {
      arguments["address"] = address;
    }
    if (threadId != null && threadId >= 0) {
      arguments["thread_id"] = threadId;
    }
    if (order == SmsOrder.asc) {
      arguments["order"] = "date ASC";
    } else if (order == SmsOrder.desc) {
      arguments["order"] = "date DESC";
    }

    String function;
    SmsMessageKind msgKind;
    if (kind == SmsQueryKind.inbox) {
      function = "getInbox";
      msgKind = SmsMessageKind.received;
    } else if (kind == SmsQueryKind.sent) {
      function = "getSent";
      msgKind = SmsMessageKind.sent;
    } else {
      function = "getDraft";
      msgKind = SmsMessageKind.draft;
    }

    var snapshot = await _channel.invokeMethod(function, arguments);
    return snapshot.map<SmsMessage>(
      (var data) {
        var msg = SmsMessage.fromJson(data);
        msg.kind = msgKind;
        return msg;
      },
    ).toList();
  }

  /// Query a list of SMS
  Future<List<SmsMessage>> querySms({
    int? start,
    int? count,
    String? address,
    int? threadId,
    List<SmsQueryKind> kinds = const [SmsQueryKind.inbox],
    SmsOrder? order,
  }) async {
    List<SmsMessage> result = [];
    for (var kind in kinds) {
      result.addAll(await _querySms(
        start: start,
        count: count,
        address: address,
        threadId: threadId,
        kind: kind,
        order: order,
      ));
    }

    return (result);
  }

  /// Get all SMS
  Future<List<SmsMessage>> get getAllSms async {
    return querySms(kinds: [
      SmsQueryKind.sent,
      SmsQueryKind.inbox,
      SmsQueryKind.draft,
    ]);
  }

  Future<SmsMessage?> get getMostRecentSms async {
    var messages = await querySms(
      count: 1,
      order: SmsOrder.desc,
    );
    if (messages.isNotEmpty) {
      return messages[0];
    }
    return null;
  }
}
