import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'anchor_scroll_controller.dart';

/// The wrapper widget which helps to get the offset of the item
/// If the size of items are fixed, there is no need to wrap the widget to item
class AnchorItemWrapper extends StatefulWidget {
  AnchorItemWrapper({
    required this.index,
    required this.child,
    this.controller,
    this.scrollViewWrapper,
    Key? key,
  })  : assert(controller != null || scrollViewWrapper != null,
            "must has AnchorScrollController or AnchorScrollViewWrapper"),
        super(key: key ?? ValueKey(index));

  final AnchorScrollController? controller;
  final int index;
  final Widget child;
  final AnchorScrollViewWrapper? scrollViewWrapper;

  @override
  AnchorItemWrapperState createState() => AnchorItemWrapperState();
}

class AnchorItemWrapperState extends State<AnchorItemWrapper> {
  @override
  void initState() {
    super.initState();
    _addItem(widget.index);
  }

  @override
  void dispose() {
    _removeItem(widget.index);
    super.dispose();
  }

  @override
  void didUpdateWidget(AnchorItemWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index || oldWidget.key != widget.key) {
      _removeItem(oldWidget.index);
      _addItem(widget.index);
    }
  }

  void _addItem(int index) {
    if (widget.controller != null) {
      widget.controller!.addItem(index, this);
    } else if (widget.scrollViewWrapper != null) {
      widget.scrollViewWrapper!.addItem(index, this);
    }
  }

  void _removeItem(int index) {
    if (widget.controller != null) {
      widget.controller!.removeItem(index);
    } else if (widget.scrollViewWrapper != null) {
      widget.scrollViewWrapper!.removeItem(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class AnchorScrollViewWrapper extends InheritedWidget {
  AnchorScrollViewWrapper({
    required this.controller,
    required Widget child,
    this.fixedItemSize,
    this.onIndexChanged,
    this.anchorOffset,
    double? pinGroupTitleOffset,
    Key? key,
  }) : super(key: key, child: child) {
    _helper = AnchorScrollControllerHelper(
      scrollController: controller,
      fixedItemSize: fixedItemSize,
      onIndexChanged: onIndexChanged,
      anchorOffset: anchorOffset,
      pinGroupTitleOffset: pinGroupTitleOffset,
    );
    _scrollListener = () {
      _helper.notifyIndexChanged();
    };
  }

  final ScrollController controller;

  final double? fixedItemSize;

  final IndexChanged? onIndexChanged;

  final double? anchorOffset;

  late final AnchorScrollControllerHelper _helper;

  late final VoidCallback _scrollListener;

  void addItem(int index, AnchorItemWrapperState state) {
    _helper.addItem(index, state);
  }

  void removeItem(int index) {
    _helper.removeItem(index);
  }

  void addIndexListener(IndexChanged indexListener) {
    _helper.addIndexListener(indexListener);
  }

  void removeIndexListener(IndexChanged indexListener) {
    _helper.removeIndexListener(indexListener);
  }

  static AnchorScrollViewWrapper? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AnchorScrollViewWrapper>();
  }

  @override
  bool updateShouldNotify(AnchorScrollViewWrapper oldWidget) {
    oldWidget._removeScrollListener();
    _addScrollListener();
    return false;
  }

  @override
  InheritedElement createElement() {
    _addScrollListener();
    return super.createElement();
  }

  void _addScrollListener() {
    controller.addListener(_scrollListener);
  }

  void _removeScrollListener() {
    controller.removeListener(_scrollListener);
  }

  Future<void> scrollToIndex({
    required int index,
    double scrollSpeed = 2,
    Curve curve = Curves.linear,
  }) async {
    _helper.scrollToIndex(index: index, scrollSpeed: scrollSpeed, curve: curve);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ScrollController>(
        'controller', controller,
        ifNull: 'no controller', showName: false));
  }
}
