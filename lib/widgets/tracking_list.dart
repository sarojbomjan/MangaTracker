import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_providers.dart';
import 'package:provider/provider.dart';
import '../constants/api.dart';
import '../models/anime.dart';
import '../providers/anime_provider.dart';
import '../screens/anime_detail.dart';
import 'skeleton_loading.dart';

class TrackingList extends StatefulWidget {
  const TrackingList({super.key});

  @override
  State<TrackingList> createState() => _TrackingListState();
}

class _TrackingListState extends State<TrackingList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<void> _trackingFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTrackingData();
  }

  void _loadTrackingData() {
    final authProvider = Provider.of<AuthProviders>(context, listen: false);
    final animeProvider = Provider.of<AnimeProvider>(context, listen: false);

    _trackingFuture = animeProvider.fetchUserTracking(authProvider.token);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _trackingFuture,
      builder: (context, snapshot) {
        return Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                Tab(
                    text:
                        TrackingStatus.getDisplayName(TrackingStatus.watching)),
                Tab(
                    text: TrackingStatus.getDisplayName(
                        TrackingStatus.completed)),
                Tab(
                    text: TrackingStatus.getDisplayName(
                        TrackingStatus.planToWatch)),
                Tab(
                    text:
                        TrackingStatus.getDisplayName(TrackingStatus.dropped)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TrackingListView(
                    status: TrackingStatus.watching,
                    isLoading:
                        snapshot.connectionState == ConnectionState.waiting,
                  ),
                  _TrackingListView(
                    status: TrackingStatus.completed,
                    isLoading:
                        snapshot.connectionState == ConnectionState.waiting,
                  ),
                  _TrackingListView(
                    status: TrackingStatus.planToWatch,
                    isLoading:
                        snapshot.connectionState == ConnectionState.waiting,
                  ),
                  _TrackingListView(
                    status: TrackingStatus.dropped,
                    isLoading:
                        snapshot.connectionState == ConnectionState.waiting,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrackingListView extends StatelessWidget {
  final String status;
  final bool isLoading;

  const _TrackingListView({
    required this.status,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Show skeleton loading while loading
    if (isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return const AnimeListItemSkeleton();
        },
      );
    }

    final animeProvider = Provider.of<AnimeProvider>(context);

    // Filter tracking items by status
    final trackingItems = animeProvider.userTracking
        .where(
          (item) => item.status == status,
        )
        .toList();

    if (trackingItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No anime in this list yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: trackingItems.length,
      itemBuilder: (context, index) {
        final tracking = trackingItems[index];

        // Find the anime details for this tracking item
        final anime = animeProvider.animeList.firstWhere(
          (anime) => anime.id == tracking.animeId,
          orElse: () => Anime(
            id: tracking.animeId,
            title: 'Unknown Anime',
            type: 'unknown',
            episodes: 0,
            status: 'unknown',
            rating: 0,
            genres: [],
          ),
        );

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              anime.coverImage ?? '/placeholder.svg?height=60&width=40',
              width: 40,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 40,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                );
              },
            ),
          ),
          title: Text(anime.title),
          subtitle: Text('Progress: ${tracking.progress}/${anime.episodes}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AnimeDetailScreen(anime: anime),
              ),
            );
          },
        );
      },
    );
  }
}
