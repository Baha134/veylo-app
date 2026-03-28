// lib/features/feed/bloc/feed_event.dart

abstract class FeedEvent {}

class FeedLoadRequested extends FeedEvent {}

class FeedLoadMoreRequested extends FeedEvent {}

class FeedFilterChanged extends FeedEvent {
  final String? city;
  final int? ageMin;
  final int? ageMax;
  FeedFilterChanged({this.city, this.ageMin, this.ageMax});
}

class FeedSendRequest extends FeedEvent {
  final String toUid;
  FeedSendRequest(this.toUid);
}
