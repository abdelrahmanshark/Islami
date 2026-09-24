import 'package:flutter/material.dart';
import 'package:islami/ui/home/widgets/sura_search_bar.dart';

/// Lazy list that smoothly scrolls to the card at [activeIndex] whenever
/// [scrollRequested] is true (set by a mini player tap), then calls
/// [onScrollHandled] so the request runs only once.
class ActiveAudioListView extends StatefulWidget {
  const ActiveAudioListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.activeIndex,
    required this.scrollRequested,
    required this.onScrollHandled,
    this.separatorBuilder,
    this.padding,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Index of the playing audio card; null when it is not in the list.
  final int? activeIndex;
  final bool scrollRequested;
  final VoidCallback onScrollHandled;
  final IndexedWidgetBuilder? separatorBuilder;
  final EdgeInsetsGeometry? padding;

  @override
  State<ActiveAudioListView> createState() => _ActiveAudioListViewState();
}

class _ActiveAudioListViewState extends State<ActiveAudioListView> {
  static const Duration _approachDuration = Duration(milliseconds: 600);
  static const Duration _revealDuration = Duration(milliseconds: 400);
  static const Duration _scrollToTopDuration = Duration(milliseconds: 400);
  static const int _maxApproachAttempts = 5;

  final ScrollController _scrollController = ScrollController();

  // One stable key per index, so the active card can be found once built
  // without remounting cards when the active index changes.
  final Map<int, GlobalKey> _itemKeys = <int, GlobalKey>{};

  bool _isScrolling = false;
  bool _stopActiveScroll = false;

  @override
  void initState() {
    super.initState();
    SuraSearchBar.activationCount.addListener(_onSearchActivated);
    _scheduleScroll();
  }

  @override
  void didUpdateWidget(covariant ActiveAudioListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleScroll();
  }

  @override
  void dispose() {
    SuraSearchBar.activationCount.removeListener(_onSearchActivated);
    _scrollController.dispose();
    super.dispose();
  }

  /// Returns the stable key of the card at [index].
  GlobalKey _keyForIndex(int index) {
    return _itemKeys.putIfAbsent(index, () => GlobalKey());
  }

  /// Smoothly scrolls back to the first card when a search bar is tapped.
  void _onSearchActivated() {
    // Ignore taps from another screen pushed on top of this list.
    final bool isOnCurrentScreen = ModalRoute.isCurrentOf(context) ?? true;
    if (!isOnCurrentScreen || !_scrollController.hasClients) return;

    // Stops a mini player scroll that is still moving to the active card.
    if (_isScrolling) _stopActiveScroll = true;

    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: _scrollToTopDuration,
      curve: Curves.easeInOut,
    );
  }

  /// Starts the scroll after this frame, once the list has been laid out.
  void _scheduleScroll() {
    if (!widget.scrollRequested || _isScrolling) return;
    _isScrolling = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveCard());
  }

  /// Scrolls near the active card until it is built, then centers it.
  Future<void> _scrollToActiveCard() async {
    for (int attempt = 0; attempt < _maxApproachAttempts; attempt++) {
      final int? index = widget.activeIndex;
      if (!mounted || _stopActiveScroll) break;
      if (index == null || !_scrollController.hasClients) break;
      if (_keyForIndex(index).currentContext != null) break;

      // Lazy lists only build cards near the viewport, so move close first.
      await _scrollController.animateTo(
        _estimatedOffsetFor(index),
        duration: _approachDuration,
        curve: Curves.easeInOut,
      );
      await WidgetsBinding.instance.endOfFrame;
    }

    final int? index = widget.activeIndex;
    final BuildContext? cardContext = index == null
        ? null
        : _keyForIndex(index).currentContext;
    final bool canReveal =
        mounted && !_stopActiveScroll && cardContext != null;
    if (canReveal && cardContext.mounted) {
      await Scrollable.ensureVisible(
        cardContext,
        alignment: 0.5,
        duration: _revealDuration,
        curve: Curves.easeInOut,
      );
    }

    _isScrolling = false;
    _stopActiveScroll = false;
    // If the list was replaced mid-scroll (e.g. reloading), keep the request
    // so the new list can handle it.
    if (mounted) {
      widget.onScrollHandled();
    }
  }

  /// Estimated scroll offset that centers the card at [index].
  double _estimatedOffsetFor(int index) {
    final ScrollPosition position = _scrollController.position;
    final double viewport = position.viewportDimension;
    // The list only knows built cards, so use the average card height.
    final double averageExtent =
        (position.maxScrollExtent + viewport) / widget.itemCount;
    final double offset =
        averageExtent * index - (viewport - averageExtent) / 2;
    return offset.clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return KeyedSubtree(
          key: _keyForIndex(index),
          child: widget.itemBuilder(context, index),
        );
      },
      separatorBuilder:
          widget.separatorBuilder ??
          (context, index) => const SizedBox.shrink(),
    );
  }
}
