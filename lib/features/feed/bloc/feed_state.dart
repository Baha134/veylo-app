// lib/features/feed/bloc/feed_state.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_profile.dart';

enum FeedStatus { initial, loading, loadingMore, success, failure }

class FeedState {
  final FeedStatus status;
  final List<FeedProfile> profiles;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final String? error;
  final Set<String> sentRequests; // uid-ы, которым уже отправили запрос

  const FeedState({
    this.status = FeedStatus.initial,
    this.profiles = const [],
    this.hasMore = true,
    this.lastDoc,
    this.error,
    this.sentRequests = const {},
  });

  FeedState copyWith({
    FeedStatus? status,
    List<FeedProfile>? profiles,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    String? error,
    Set<String>? sentRequests,
  }) => FeedState(
    status: status ?? this.status,
    profiles: profiles ?? this.profiles,
    hasMore: hasMore ?? this.hasMore,
    lastDoc: lastDoc ?? this.lastDoc,
    error: error ?? this.error,
    sentRequests: sentRequests ?? this.sentRequests,
  );
}
