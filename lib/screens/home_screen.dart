import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_providers.dart';
import 'package:provider/provider.dart';
import '../models/anime.dart';
import '../providers/anime_provider.dart';
import '../widgets/anime_card.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/tracking_list.dart';
import 'anime_detail.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'seasonal_anime.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late Future<void> _dataFuture;
  late Future<List<Anime>> _airingAnimeFuture;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final authProvider = Provider.of<AuthProviders>(context, listen: false);
    final animeProvider = Provider.of<AnimeProvider>(context, listen: false);

    // Initialize the futures
    _dataFuture = Future.wait([
      animeProvider.fetchAnimeList(authProvider.token),
      animeProvider.fetchUserTracking(authProvider.token),
    ]);

    _airingAnimeFuture = animeProvider.fetchCurrentlyAiring();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MangaDesk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'My List',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildMyListTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final animeProvider = Provider.of<AnimeProvider>(context);

    return FutureBuilder<void>(
      future: _dataFuture,
      builder: (context, snapshot) {
        // Show error if there's an error
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading data',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(snapshot.error.toString()),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _initializeData();
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Always show UI, even while loading
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with seasonal button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top Anime',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SeasonalAnimeScreen()),
                      );
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Seasonal'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Top Anime horizontal list
              SizedBox(
                height: 200,
                child: snapshot.connectionState == ConnectionState.waiting ||
                        animeProvider.animeList.isEmpty
                    ? _buildHorizontalSkeletonList()
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: animeProvider.animeList.length,
                        itemBuilder: (context, index) {
                          final anime = animeProvider.animeList[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AnimeDetailScreen(anime: anime),
                                ),
                              );
                            },
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 12),
                              child: AnimeCard(anime: anime),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 24),

              // Currently Airing Anime Section
              Text(
                'Currently Airing',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Currently Airing horizontal list with FutureBuilder
              SizedBox(
                height: 200,
                child: FutureBuilder<List<Anime>>(
                  future: _airingAnimeFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildHorizontalSkeletonList();
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                            'Error loading airing anime: ${snapshot.error}'),
                      );
                    }

                    final airingAnime = snapshot.data ?? [];

                    if (airingAnime.isEmpty) {
                      return const Center(
                        child: Text('No currently airing anime found.'),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: airingAnime.length,
                      itemBuilder: (context, index) {
                        final anime = airingAnime[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AnimeDetailScreen(anime: anime),
                              ),
                            );
                          },
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
                            child: AnimeCard(anime: anime),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Your Watchlist section
              Text(
                'Your Watchlist',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Watchlist with conditional rendering
              snapshot.connectionState == ConnectionState.waiting
                  ? Column(
                      children: List.generate(
                        3,
                        (index) => const AnimeListItemSkeleton(),
                      ),
                    )
                  : animeProvider.userTracking.isEmpty
                      ? const Text(
                          'Your watchlist is empty. Add some anime to get started!')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: animeProvider.userTracking.length > 5
                              ? 5
                              : animeProvider.userTracking.length,
                          itemBuilder: (context, index) {
                            final tracking = animeProvider.userTracking[index];
                            final anime = animeProvider.animeList.firstWhere(
                              (a) => a.id == tracking.animeId,
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
                                  anime.coverImage ??
                                      '/placeholder.svg?height=60&width=40',
                                  width: 40,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 40,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child:
                                          const Icon(Icons.image_not_supported),
                                    );
                                  },
                                ),
                              ),
                              title: Text(anime.title),
                              subtitle: Text(
                                  'Progress: ${tracking.progress}/${anime.episodes}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AnimeDetailScreen(anime: anime),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyListTab() {
    return const TrackingList();
  }

  Widget _buildHorizontalSkeletonList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) {
        return const AnimeCardSkeleton();
      },
    );
  }
}
