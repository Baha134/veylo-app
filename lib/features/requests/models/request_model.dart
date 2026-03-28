// lib/features/requests/models/request_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { pending, accepted, declined }

class RequestModel {
  final String id;
  final String fromUid;
  final String toUid;
  final RequestStatus status;
  final DateTime createdAt;
  final String? message;

  const RequestModel({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
    this.message,
  });

  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RequestModel(
      id: doc.id,
      fromUid: data['fromUid'] ?? '',
      toUid: data['toUid'] ?? '',
      status: RequestStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => RequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      message: data['message'],
    );
  }

  Map<String, dynamic> toMap() => {
    'fromUid': fromUid,
    'toUid': toUid,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'message': message,
  };
}
