import 'package:flutter/material.dart';
import 'package:frontend/models/anime.dart';
import 'package:frontend/providers/anime_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/anime_card.dart';
import '../widgets/skeleton_loading.dart';
import 'anime_detail.dart';

class SeasonalAnimeScreen extends StatefulWidget {
  const SeasonalAnimeScreen({super.key});

  @override
  State<SeasonalAnimeScreen> createState() => _SeasonalAnimeScreenState();
}

class _SeasonalAnimeScreenState extends State<SeasonalAnimeScreen> {
  String _selectedYear = DateTime.now().year.toString();
  String _selectedSeason = _getCurrentSeason();
  Future<List<Anime>>? _seasonalAnimeFuture;

  @override
  void initState() {
    super.initState();
    _fetchSeasonalAnime();
  }

  static String _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'fall';
    return 'winter';
  }

  void _fetchSeasonalAnime() {
    final animeProvider = Provider.of<AnimeProvider>(context, listen: false);
    setState(() {
      _seasonalAnimeFuture = animeProvider.fetchAnimeBySeason(
          int.parse(_selectedYear), _selectedSeason);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seasonal Anime'),
      ),
      body: Column(
        children: [
          // Season selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Year dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem<String>(
                        value: year.toString(),
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null && value != _selectedYear) {
                        setState(() {
                          _selectedYear = value;
                        });
                        _fetchSeasonalAnime();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Season dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSeason,
                    decoration: const InputDecoration(
                      labelText: 'Season',
                      border: OutlineInputBorder(),
                    ),
                    items: ['winter', 'spring', 'summer', 'fall'].map((season) {
                      return DropdownMenuItem<String>(
                        value: season,
                        child: Text(season.capitalize()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null && value != _selectedSeason) {
                        setState(() {
                          _selectedSeason = value;
                        });
                        _fetchSeasonalAnime();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Anime grid with FutureBuilder
          Expanded(
            child: FutureBuilder<List<Anime>>(
              future: _seasonalAnimeFuture,
              builder: (context, snapshot) {
                // Show loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return const AnimeCardSkeleton(height: 250);
                    },
                  );
                }

                // Show error state
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading seasonal anime',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchSeasonalAnime,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Show empty results
                final seasonalAnime = snapshot.data ?? [];
                if (seasonalAnime.isEmpty) {
                  return Center(
                    child: Text(
                      'No anime found for ${_selectedSeason.capitalize()} ${_selectedYear}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }

                // Show anime grid
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: seasonalAnime.length,
                  itemBuilder: (context, index) {
                    final anime = seasonalAnime[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AnimeDetailScreen(anime: anime),
                          ),
                        );
                      },
                      child: AnimeCard(anime: anime),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
