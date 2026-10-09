import 'package:flutter/material.dart';

import '../../core/widgets/state_message.dart';
import '../../domain/repositories/bazaar_repository.dart';
import 'bazaar_controller.dart';
import 'widgets/bazaar_list.dart';
import 'widgets/bazaar_status_bar.dart';

class BazaarPage extends StatefulWidget {
  const BazaarPage({super.key, required this.repository});

  final BazaarRepository repository;

  @override
  State<BazaarPage> createState() => _BazaarPageState();
}

class _BazaarPageState extends State<BazaarPage> {
  late final BazaarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BazaarController(widget.repository)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bazaar')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => switch (_controller.state) {
          BazaarLoading() => const Center(child: CircularProgressIndicator()),
          BazaarEmpty() => const StateMessage(text: 'No bazaar items to show.'),
          BazaarError() => StateMessage(
            text: 'Could not load the bazaar. Check your connection.',
            onRetry: _controller.load,
          ),
          BazaarData(:final snapshot, :final sync) => Column(
            children: [
              BazaarStatusBar(snapshot: snapshot, sync: sync),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _controller.load,
                  child: BazaarList(snapshot: snapshot),
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}
