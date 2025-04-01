import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_providers.dart';
import 'package:provider/provider.dart';
import '../constants/api.dart';
import '../models/anime.dart';
import '../models/tracking.dart';
import '../providers/anime_provider.dart';
import '../widgets/skeleton_loading.dart';

class AnimeDetailScreen extends StatefulWidget {
  final Anime anime;

  const AnimeDetailScreen({
    super.key,
    required this.anime,
  });

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen>
    with SingleTickerProviderStateMixin {
  String _selectedStatus = TrackingStatus.planToWatch;
  int _progress = 0;
  bool _isInList = false;
  Tracking? _tracking;
  bool _isUpdating = false;
  late TabController _tabController;
  late Future<Anime?> _animeDetailsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkIfInList();
    _loadAnimeDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAnimeDetails() {
    if (widget.anime.malId == null) {
      _animeDetailsFuture = Future.value(widget.anime);
      return;
    }

    final animeProvider = Provider.of<AnimeProvider>(context, listen: false);
    _animeDetailsFuture = animeProvider.fetchAnimeById(widget.anime.malId!);
  }

  void _checkIfInList() {
    final animeProvider = Provider.of<AnimeProvider>(context, listen: false);
    final tracking = animeProvider.userTracking
        .where(
          (item) => item.animeId == widget.anime.id,
        )
        .toList();

    if (tracking.isNotEmpty) {
      setState(() {
        _isInList = true;
        _tracking = tracking.first;
        _selectedStatus = _tracking!.status;
        _progress = _tracking!.progress;
      });
    }
  }

  Future<void> _addToList() async {
    setState(() {
      _isUpdating = true;
    });

    final authProvider = Provider.of<AuthProviders>(context, listen: false);
    final animeProvider = Provider.of<AnimeProvider>(context, listen: false);

    final success = await animeProvider.addTracking(
      authProvider.token,
      widget.anime.id,
      _selectedStatus,
      _progress,
    );

    if (!mounted) return;

    setState(() {
      _isUpdating = false;
    });

    if (success) {
      setState(() {
        _isInList = true;
        _checkIfInList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to your list!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add to list. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateTracking() async {
    if (_tracking == null) return;

    setState(() {
      _isUpdating = true;
    });

    final authProvider = Provider.of<AuthProviders>(context, listen: false);
    final animeProvider = Provider.of<AnimeProvider>(context, listen: false);

    final updatedTracking = Tracking(
      id: _tracking!.id,
      animeId: widget.anime.id,
      status: _selectedStatus,
      progress: _progress,
      rating: _tracking!.rating,
      notes: _tracking!.notes,
    );

    final success = await animeProvider.updateTracking(
      authProvider.token,
      updatedTracking,
    );

    if (!mounted) return;

    setState(() {
      _isUpdating = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Updated your list!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Anime?>(
        future: _animeDetailsFuture,
        builder: (context, snapshot) {
          // Show skeleton loading while waiting
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(
              child: AnimeDetailSkeleton(),
            );
          }

          // Show error if there's an error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading anime details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadAnimeDetails();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Use detailed anime if available, otherwise use the original anime
          final anime = snapshot.data ?? widget.anime;

          return CustomScrollView(
            slivers: [
              // App bar with image
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    anime.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        anime.coverImage ??
                            '/placeholder.svg?height=300&width=500',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child:
                                const Icon(Icons.image_not_supported, size: 50),
                          );
                        },
                      ),
                      // Gradient overlay for better text visibility
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black54,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick info bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem(
                            Icons.live_tv,
                            anime.type.toUpperCase(),
                          ),
                          _buildInfoItem(
                            Icons.video_library,
                            '${anime.episodes} eps',
                          ),
                          _buildInfoItem(
                            Icons.star,
                            anime.rating.toString(),
                            color: Colors.amber,
                          ),
                          _buildInfoItem(
                            Icons.calendar_today,
                            anime.airedFrom != null
                                ? _formatDate(anime.airedFrom).substring(0, 4)
                                : 'Unknown',
                          ),
                        ],
                      ),
                    ),

                    // Tabs
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Details'),
                        Tab(text: 'My List'),
                      ],
                    ),

                    // Tab content
                    SizedBox(
                      height: 500, // Fixed height for tab content
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Details tab
                          _buildDetailsTab(anime),

                          // My List tab
                          _buildMyListTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(text),
      ],
    );
  }

  Widget _buildDetailsTab(Anime anime) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genres
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: anime.genres.map((genre) {
              return Chip(
                label: Text(genre),
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Air dates if available
          if (anime.airedFrom != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aired',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  anime.airedTo != null
                      ? '${_formatDate(anime.airedFrom)} to ${_formatDate(anime.airedTo)}'
                      : 'From ${_formatDate(anime.airedFrom)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Description
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            anime.description ?? 'No description available.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          const SizedBox(height: 24),

          // External link to MAL
          if (anime.malId != null)
            OutlinedButton.icon(
              onPressed: () {
                // Open MAL link (would need url_launcher package)
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('View on MyAnimeList'),
            ),
        ],
      ),
    );
  }

  Widget _buildMyListTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isInList ? 'Update Your Progress' : 'Add to Your List',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Status dropdown
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: TrackingStatus.getAll().map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(TrackingStatus.getDisplayName(status)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedStatus = value;
                });
              }
            },
          ),

          const SizedBox(height: 16),

          // Progress slider
          Row(
            children: [
              const Text('Progress:'),
              Expanded(
                child: Slider(
                  value: _progress.toDouble(),
                  min: 0,
                  max: widget.anime.episodes > 0
                      ? widget.anime.episodes.toDouble()
                      : 100.0,
                  divisions:
                      widget.anime.episodes > 0 ? widget.anime.episodes : 100,
                  label: _progress.toString(),
                  onChanged: (value) {
                    setState(() {
                      _progress = value.toInt();
                    });
                  },
                ),
              ),
              Text(
                  '$_progress/${widget.anime.episodes > 0 ? widget.anime.episodes : "?"}'),
            ],
          ),

          const SizedBox(height: 16),

          // Add/Update button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUpdating
                  ? null
                  : (_isInList ? _updateTracking : _addToList),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: _isUpdating
                  ? const CircularProgressIndicator()
                  : Text(_isInList ? 'Update' : 'Add to List'),
            ),
          ),
        ],
      ),
    );
  }
}
