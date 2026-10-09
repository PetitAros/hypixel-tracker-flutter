import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/widgets/skeleton.dart';
import 'package:hypixel_tracker/core/widgets/state_message.dart';

// Loads once and shows the four states: loading, data, empty, error.
// Pull to refresh and Retry both call [load] again.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.isEmpty,
    required this.emptyText,
    required this.errorText,
    required this.builder,
  });

  final Future<T> Function() load;
  final bool Function(T data) isEmpty;
  final String emptyText;
  final String errorText;

  /// Must return a scrollable, so pull to refresh works.
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future = widget.load();

  Future<void> _reload() {
    final future = widget.load();
    setState(() {
      _future = future;
    });
    // The FutureBuilder shows the error; the refresh spinner only waits.
    return future.then<void>((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    // A replaced future is ignored by FutureBuilder, so a late response
    // never overwrites a newer one.
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;

        if (snapshot.connectionState != ConnectionState.done && data == null) {
          return const SkeletonList();
        }
        if (snapshot.hasError || data == null) {
          return StateMessage(text: widget.errorText, onRetry: _reload);
        }
        if (widget.isEmpty(data)) {
          return StateMessage(text: widget.emptyText);
        }
        return RefreshIndicator(
          // Start the spinner below a see-through app bar, not behind it.
          edgeOffset: MediaQuery.paddingOf(context).top,
          onRefresh: _reload,
          child: widget.builder(context, data),
        );
      },
    );
  }
}
