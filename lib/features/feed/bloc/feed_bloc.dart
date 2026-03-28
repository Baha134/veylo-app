// lib/features/feed/bloc/feed_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/feed_repository.dart';
import '../../requests/repositories/request_repository.dart';
import '../models/feed_profile.dart';
import 'feed_event.dart';
import 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedRepository _feedRepo;
  final RequestRepository _requestRepo;

  String? _filterCity;

  FeedBloc({
    required FeedRepository feedRepository,
    required RequestRepository requestRepository,
  }) : _feedRepo = feedRepository,
       _requestRepo = requestRepository,
       super(const FeedState()) {
    on<FeedLoadRequested>(_onLoad);
    on<FeedLoadMoreRequested>(_onLoadMore);
    on<FeedFilterChanged>(_onFilterChanged);
    on<FeedSendRequest>(_onSendRequest);
  }

  Future<void> _onLoad(FeedLoadRequested event, Emitter<FeedState> emit) async {
    emit(
      state.copyWith(
        status: FeedStatus.loading,
        profiles: [],
        lastDoc: null,
        hasMore: true,
      ),
    );
    try {
      final snap = await _feedRepo.fetchProfilesRaw(filterCity: _filterCity);
      final profiles = snap.docs
          .map(
            (d) => FeedProfile.fromFirestore(
              d.data() as Map<String, dynamic>,
              d.id,
            ),
          )
          .toList();
      emit(
        state.copyWith(
          status: FeedStatus.success,
          profiles: profiles,
          lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
          hasMore: snap.docs.length == 12,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: FeedStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onLoadMore(
    FeedLoadMoreRequested event,
    Emitter<FeedState> emit,
  ) async {
    if (!state.hasMore || state.status == FeedStatus.loadingMore) return;
    emit(state.copyWith(status: FeedStatus.loadingMore));
    try {
      final snap = await _feedRepo.fetchProfilesRaw(
        lastDoc: state.lastDoc,
        filterCity: _filterCity,
      );
      final newProfiles = snap.docs
          .map(
            (d) => FeedProfile.fromFirestore(
              d.data() as Map<String, dynamic>,
              d.id,
            ),
          )
          .toList();
      emit(
        state.copyWith(
          status: FeedStatus.success,
          profiles: [...state.profiles, ...newProfiles],
          lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
          hasMore: snap.docs.length == 12,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: FeedStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onFilterChanged(
    FeedFilterChanged event,
    Emitter<FeedState> emit,
  ) async {
    _filterCity = event.city;
    add(FeedLoadRequested());
  }

  Future<void> _onSendRequest(
    FeedSendRequest event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _requestRepo.sendRequest(event.toUid);
      emit(state.copyWith(sentRequests: {...state.sentRequests, event.toUid}));
    } catch (_) {}
  }
}
