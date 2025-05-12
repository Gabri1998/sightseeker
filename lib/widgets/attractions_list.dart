import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/attraction.dart';

class AttractionsList extends StatefulWidget {
  final List<Attraction> attractions;
  final ValueChanged<Attraction> onAttractionSelected;

  const AttractionsList({
    super.key,
    required this.attractions,
    required this.onAttractionSelected,
  });

  @override
  State<AttractionsList> createState() => _AttractionsListState();
}

class _AttractionsListState extends State<AttractionsList> {
  final Map<String, bool> _expandedItems = {};

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: widget.attractions.length,
      itemBuilder: (context, index) {
        final attraction = widget.attractions[index];
        final isExpanded = _expandedItems[attraction.id] ?? false;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: InkWell(
            onTap: () {
              setState(() {
                _expandedItems[attraction.id] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (attraction.photoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            attraction.photoUrl!.toString(),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attraction.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (attraction.description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  attraction.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: isExpanded ? null : 2,
                                  overflow: isExpanded ? null : TextOverflow.ellipsis,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.directions_walk, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${attraction.distanceKm?.toStringAsFixed(1)} km',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (attraction.rating != null) ...[
                                    const SizedBox(width: 12),
                                    const Icon(Icons.star, size: 16, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      attraction.rating!.toStringAsFixed(1),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => widget.onAttractionSelected(attraction),
                          child: const Text('View Details'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}