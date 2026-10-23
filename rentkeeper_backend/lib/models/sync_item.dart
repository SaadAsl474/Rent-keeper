class SyncMutation {
  final String mutationId;
  final String entityType; // 'item', 'customer', 'challan'
  final String action; // 'create', 'update', 'delete'
  final String entityId;
  final Map<String, dynamic> payload;
  final String clientTimestamp;

  SyncMutation({
    required this.mutationId,
    required this.entityType,
    required this.action,
    required this.entityId,
    required this.payload,
    required this.clientTimestamp,
  });

  factory SyncMutation.fromMap(Map<String, dynamic> map) {
    return SyncMutation(
      mutationId: map['mutationId']?.toString() ?? '',
      entityType: map['entityType']?.toString() ?? '',
      action: map['action']?.toString() ?? 'update',
      entityId: map['entityId']?.toString() ?? '',
      payload: Map<String, dynamic>.from(map['payload'] as Map? ?? {}),
      clientTimestamp: map['clientTimestamp']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mutationId': mutationId,
      'entityType': entityType,
      'action': action,
      'entityId': entityId,
      'payload': payload,
      'clientTimestamp': clientTimestamp,
    };
  }
}
