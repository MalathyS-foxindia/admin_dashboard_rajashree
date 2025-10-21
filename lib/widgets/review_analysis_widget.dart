import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewAnalysisWidget extends StatefulWidget {
  final String variantId;
  final String variantName;

  const ReviewAnalysisWidget({
    super.key,
    required this.variantId,
    required this.variantName,
  });

  @override
  State<ReviewAnalysisWidget> createState() => _ReviewAnalysisWidgetState();
}

class _ReviewAnalysisWidgetState extends State<ReviewAnalysisWidget> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;
  String _filter = 'active'; // can be 'active', 'inactive', or 'all'
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _loading = true);

    try {
      // Base query
      var query = supabase.from('reviews').select().eq('variant_id', widget.variantId);

      // Apply filter only if not "all"
      if (_filter != 'all') {
        final isActive = _filter == 'active';
        query = query.eq('status', isActive);
      }

      final response = await query;

      final list = (response as List).cast<Map<String, dynamic>>();
      if (list.isNotEmpty) {
        final ratings = list.map((r) => (r['rating'] as num?)?.toInt() ?? 0).toList();
        _averageRating =
            ratings.isNotEmpty ? ratings.reduce((a, b) => a + b) / ratings.length : 0.0;
        _reviews = list;
      } else {
        _reviews = [];
        _averageRating = 0.0;
      }
    } catch (e, st) {
      print('Error fetching reviews: $e\n$st');
      _reviews = [];
      _averageRating = 0.0;
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleReviewStatus(String reviewId, bool currentStatus) async {
    final newStatus = !currentStatus;

    await supabase
        .from('reviews')
        .update({'status': newStatus})
        .eq('review_id', reviewId);

    _fetchReviews(); // refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews - ${widget.variantName}'),
        actions: [
          DropdownButton<String>(
            value: _filter,
            items: const [
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              DropdownMenuItem(value: 'all', child: Text('All')),
            ],
            onChanged: (v) {
              setState(() => _filter = v ?? 'active');
              _fetchReviews();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? const Center(child: Text('No reviews found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _reviews.length,
                  itemBuilder: (context, i) {
                    final r = _reviews[i];
                    final color = r['sentiment'] == 'positive'
                        ? Colors.green
                        : r['sentiment'] == 'negative'
                            ? Colors.red
                            : Colors.grey;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(
                          r['comment'] ?? '(No comment)',
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  index < (r['rating'] ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sentiment: ${r['sentiment'] ?? 'N/A'} (${(r['sentiment_score'] ?? 0).toStringAsFixed(2)})',
                              style: TextStyle(color: color),
                            ),
                            if (r['summary'] != null)
                              Text(
                                'AI Summary: ${r['summary']}',
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic, fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            (r['status'] == false)
                                ? Icons.toggle_off
                                : Icons.toggle_on,
                            color: (r['status'] == false)
                                ? Colors.grey
                                : Colors.green,
                            size: 30,
                          ),
                          onPressed: () => _toggleReviewStatus(
                            r['review_id'],
                            r['status'] == true,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: _averageRating > 0
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '⭐ Average Rating: ${_averageRating.toStringAsFixed(1)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
