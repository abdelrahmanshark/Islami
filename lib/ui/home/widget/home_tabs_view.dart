import 'package:flutter/material.dart';
import 'package:islami/utils/app_animations.dart';

/// Shows the selected home tab and keeps visited tabs alive, so their
/// scroll positions and state survive tab switches.
///
/// Each tab is built the first time it is opened (not all at startup),
/// and the newly selected tab fades in quickly.
class HomeTabsView extends StatefulWidget {
  const HomeTabsView({
    super.key,
    required this.selectedIndex,
    required this.tabs,
  });

  final int selectedIndex;
  final List<Widget> tabs;

  @override
  State<HomeTabsView> createState() => _HomeTabsViewState();
}

class _HomeTabsViewState extends State<HomeTabsView>
    with SingleTickerProviderStateMixin {
  // Starts at 1 so the first tab shows without a fade.
  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: AppAnimations.fast,
    value: 1,
  );

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _fadeController,
    curve: AppAnimations.curve,
  );

  // Tabs that were opened at least once.
  late final Set<int> _visitedTabs = <int>{widget.selectedIndex};

  @override
  void didUpdateWidget(covariant HomeTabsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _visitedTabs.add(widget.selectedIndex);
      _fadeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    for (int index = 0; index < widget.tabs.length; index++) {
      final bool isSelected = index == widget.selectedIndex;
      if (!_visitedTabs.contains(index)) {
        children.add(const SizedBox.shrink());
        continue;
      }
      // Hidden tabs stop their animations and cannot hold keyboard focus.
      children.add(
        TickerMode(
          enabled: isSelected,
          child: ExcludeFocus(
            excluding: !isSelected,
            child: widget.tabs[index],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: IndexedStack(index: widget.selectedIndex, children: children),
    );
  }
}
