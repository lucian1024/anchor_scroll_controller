library anchor_scroll_controller;

import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'anchor_scroll_wrapper.dart';

typedef IndexChanged = void Function(int index, bool userScroll);

mixin AnchorScrollControllerMixin {
  /// The fixed item size
  /// If the [ScrollView] scrolls along vertical, it should be the fixed height of the item
  /// If the [ScrollView] scrolls along horizontal, it should be the fixed width of the item
  late final double? fixedItemSize;

  /// The map which stores the states of the current items in the viewport
  final Map<int, AnchorItemWrapperState> _itemMap = {};

  void addItem(int index, AnchorItemWrapperState state) {
    _itemMap[index] = state;
  }

  void removeItem(int index) {
    _itemMap.remove(index);
  }

  /// current index
  int _currIndex = 0;
  int get currIndex => _currIndex;

  /// callback when current index changed
  late final IndexChanged? onIndexChanged;

  double _lastOffset = 0;
  void notifyIndexChanged(ScrollController controller) {
    // if the scroll behavior is triggered by user, notify index changed
    if (controller.hasClients &&
        controller.offset >= controller.position.minScrollExtent) {
      if (controller.offset < controller.position.maxScrollExtent ||
          (controller.offset == controller.position.maxScrollExtent &&
              _lastOffset < controller.position.maxScrollExtent)) {
        final index = _getCurrIndex(controller);
        if (index != _currIndex) {
          _currIndex = index;
          onIndexChanged?.call(_currIndex,
              controller.position.userScrollDirection != ScrollDirection.idle);
        }
      }
    }

    if (controller.offset >= controller.position.minScrollExtent &&
        controller.offset <= controller.position.maxScrollExtent) {
      _lastOffset = controller.offset;
    }
  }

  int _getCurrIndex(ScrollController controller) {
    int? tmpIndex;
    for (final index in _itemMap.keys.toList()) {
      final RevealedOffset? revealedOffset = _getOffsetToReveal(index);
      if (revealedOffset == null) {
        continue;
      }

      if (revealedOffset.offset <= controller.offset &&
          revealedOffset.offset + revealedOffset.rect.height >
              controller.offset) {
        tmpIndex = index;
        break;
      }
    }

    // there is no item for current scroll offset, which only happens with the ScrollView that supports pin.
    // In this case, we need to find a item which satisfies its offset plus its height
    // is smaller than the current scroll offset and the current scroll offset
    // is smaller than the offset of the next item
    if (tmpIndex == null) {
      int index = _currIndex;
      RevealedOffset? revealedOffset = _getOffsetToReveal(index);
      while (revealedOffset != null) {
        if (controller.offset >
            revealedOffset.offset + revealedOffset.rect.height) {
          RevealedOffset? nextRevealedOffset = _getOffsetToReveal(index + 1);
          if (nextRevealedOffset != null) {
            if (controller.offset < nextRevealedOffset.offset) {
              break;
            } else {
              index++;
              revealedOffset = _getOffsetToReveal(index);
            }
          } else {
            break;
          }
        } else {
          RevealedOffset? preRevealedOffset = _getOffsetToReveal(index - 1);
          if (preRevealedOffset != null) {
            index--;
            if (controller.offset >
                preRevealedOffset.offset + preRevealedOffset.rect.height) {
              break;
            } else {
              revealedOffset = _getOffsetToReveal(index);
            }
          } else {
            break;
          }
        }
      }

      tmpIndex = index;
    }

    return tmpIndex;
  }

  /// whether is scrolling to some index currently
  bool _isScrollingToIndex = false;

  /// Scroll to index
  ///
  /// @param controller: the ScrollController of the ScrollView
  /// @param index: the target index item to scroll to
  /// @param scrollSpeed: the scroll speed in unit offset/millisecond
  /// @param curve: the scroll animation
  Future<void> scrollToIndexWithScrollController(
      {required ScrollController controller,
      required int index,
      double scrollSpeed = 2,
      Curve curve = Curves.linear}) async {
    assert(scrollSpeed > 0);

    if (!controller.hasClients) {
      return;
    }

    // If it's scrolling to some index currently, stop it and
    // then calculate current index first
    if (_isScrollingToIndex) {
      _isScrollingToIndex = false;
      // No API has been found to interrupt scrolling.
      // According to the description of the [ScrollPosition.animateTo],
      // then animation will be interrupted whenever the user attempts to scroll manually,
      // or whenever another activity is started, or whenever the another activity is started,
      // or whenever the animation reaches the edge of the viewport and attempts to overscroll.
      // So, create a new scroll behavior to stop the last one.
      // Maybe there is a better way to do this.
      await controller.animateTo(controller.offset,
          duration: Duration(milliseconds: 1), curve: curve);
      _currIndex = _getCurrIndex(controller);
    }

    _isScrollingToIndex = true;

    if (fixedItemSize != null) {
      // if the item size is fixed, the target offset is index * fixedItemSize
      final targetOffset = index * fixedItemSize!;
      final int scrollTime =
          ((controller.offset - targetOffset).abs() / scrollSpeed).round();
      final Duration duration = Duration(milliseconds: scrollTime);
      await controller.animateTo(targetOffset,
          duration: duration, curve: curve);
    } else {
      // if the item size is not fixed, there are two cases to consider.
      // 1. if the target index item is already in viewport, we can get the target offset directly
      // 2. if the target index item is not in viewport, we should scroll to the first or last item in
      //    the viewport. And then we will get some more items in the viewport which are closer to
      //    the target item. Repeat the above steps until the target item is in the viewport and then
      //    we can get its offset and scroll to it.
      if (_itemMap.containsKey(index)) {
        await _animateToIndexInViewport(controller, index, scrollSpeed, curve);
      } else {
        int tmpIndex = _currIndex;
        while (!_itemMap.containsKey(index)) {
          final sortedKeys = _itemMap.keys.toList()
            ..sort((first, second) => first.compareTo(second));
          tmpIndex = (tmpIndex < index) ? sortedKeys.last : sortedKeys.first;
          double alignment = (tmpIndex < index) ? 1 : 0;
          await _animateToIndexInViewport(
              controller, tmpIndex, scrollSpeed, curve,
              alignment: alignment);
          if (!_isScrollingToIndex) {
            // this scrolling is interrupted
            return;
          }
        }

        await _animateToIndexInViewport(controller, index, scrollSpeed, curve);
      }

      // sometimes the offset of items may change, for example, the height of the item changes
      // after rebuild, which makes it cannot scroll to the index exactly. So, jump to the exact
      // offset in finally.
      final targetScrollOffset = _getScrollOffset(controller, index);
      if (targetScrollOffset != null &&
          controller.offset != targetScrollOffset) {
        controller.jumpTo(targetScrollOffset);
      }

      _currIndex = index;
      _isScrollingToIndex = false;
    }
  }

  /// Scroll to the index item which is already in the viewport
  Future<void> _animateToIndexInViewport(
      ScrollController controller, int index, double scrollSpeed, Curve curve,
      {double alignment = 0}) async {
    final double? targetOffset =
        _getScrollOffset(controller, index, alignment: alignment);
    if (targetOffset == null) {
      return;
    }

    final int scrollTime =
        ((controller.offset - targetOffset).abs() / scrollSpeed).ceil();
    final Duration duration = Duration(milliseconds: scrollTime);
    await controller.animateTo(targetOffset, duration: duration, curve: curve);
  }

  /// Get the scroll offset for the target index
  double? _getScrollOffset(ScrollController controller, int index,
      {double alignment = 0}) {
    final revealOffset = _getOffsetToReveal(index, alignment: alignment);
    if (revealOffset == null) {
      return null;
    }

    return revealOffset.offset.clamp(controller.position.minScrollExtent,
        controller.position.maxScrollExtent);
  }

  /// Get the [RevealedOffset] to reveal the target index
  RevealedOffset? _getOffsetToReveal(int index, {double alignment = 0}) {
    RevealedOffset? offset;

    final context = _itemMap[index]?.context;
    if (context != null) {
      final renderBox = context.findRenderObject();
      final viewport = RenderAbstractViewport.of(renderBox);
      if (renderBox != null && viewport != null) {
        offset = viewport.getOffsetToReveal(renderBox, 0);
      }
    }

    return offset;
  }
}

class AnchorScrollController extends ScrollController
    with AnchorScrollControllerMixin {
  AnchorScrollController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String? debugLabel,
    this.onIndexChanged,
    this.fixedItemSize,
  }) : super(
            initialScrollOffset: initialScrollOffset,
            keepScrollOffset: keepScrollOffset,
            debugLabel: debugLabel);

  final double? fixedItemSize;

  final IndexChanged? onIndexChanged;

  @override
  void notifyListeners() {
    notifyIndexChanged(this);

    super.notifyListeners();
  }

  Future<void> scrollToIndex(
      {required int index,
      double scrollSpeed = 2,
      Curve curve = Curves.linear}) async {
    await scrollToIndexWithScrollController(
        controller: this, index: index, scrollSpeed: scrollSpeed, curve: curve);
  }
}
