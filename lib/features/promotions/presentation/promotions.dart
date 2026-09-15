import 'package:flutter/material.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';

class Promotions extends StatefulWidget {
  const Promotions({super.key});

  @override
  State<Promotions> createState() => _PromotionsState();
}

class _PromotionsState extends State<Promotions> {
  int _selectedTab = 1;

  @override
  Widget build(BuildContext context) {
    final saved = _selectedTab == 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.bookmark_border_rounded),
                  label: Text('Saved'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.local_offer_outlined),
                  label: Text('Promotions'),
                ),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (selection) {
                setState(() => _selectedTab = selection.single);
              },
            ),
          ),
          Expanded(
            child: Center(
              child: MoveraEmptyState(
                icon: saved
                    ? Icons.bookmark_border_rounded
                    : Icons.local_offer_outlined,
                title: saved
                    ? 'No saved promotions'
                    : 'No promotions available',
                message: saved
                    ? 'Promotions you save will appear here.'
                    : 'New verified ride offers will appear here when they '
                          'are available.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
