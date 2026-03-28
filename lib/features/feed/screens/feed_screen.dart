// lib/features/feed/screens/feed_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/feed_state.dart';
import '../widgets/profile_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<FeedBloc>().add(FeedLoadRequested());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Подгружаем, когда до конца осталось 300px
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<FeedBloc>().add(FeedLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Veylo',
          style: TextStyle(
            color: Color(0xFF7B4FA6),
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        actions: [
          // Кнопка входящих запросов
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF7B4FA6),
            ),
            onPressed: () => Navigator.pushNamed(context, '/requests'),
          ),
          // Фильтры
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF7B4FA6)),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: BlocBuilder<FeedBloc, FeedState>(
        builder: (context, state) {
          if (state.status == FeedStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7B4FA6)),
            );
          }

          if (state.status == FeedStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Что-то пошло не так'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<FeedBloc>().add(FeedLoadRequested()),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (state.profiles.isEmpty && state.status == FeedStatus.success) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🌸', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text(
                    'Пока никого нет поблизости',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final profile = state.profiles[index];
                    return ProfileCard(
                      profile: profile,
                      requestSent: state.sentRequests.contains(profile.uid),
                      onSendRequest: () => context.read<FeedBloc>().add(
                        FeedSendRequest(profile.uid),
                      ),
                    );
                  }, childCount: state.profiles.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.62, // высокая карточка под силуэт
                  ),
                ),
              ),
              // Лоадер внизу при подгрузке
              if (state.status == FeedStatus.loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7B4FA6),
                      ),
                    ),
                  ),
                ),
              // Конец ленты
              if (!state.hasMore && state.profiles.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Ты просмотрел всех 👀',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showFilters() {
    String? selectedCity;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Фильтры',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text('Город', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Например: Алматы',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (v) => selectedCity = v.trim(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<FeedBloc>().add(
                    FeedFilterChanged(city: selectedCity),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B4FA6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Применить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
