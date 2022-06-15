library anchor_scroll_controller;

import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'anchor_scroll_wrapper.dart';

typedef IndexChanged = void Function(int index, bool userScroll);

class AnchorScrollControllerHelper {
  AnchorScrollControllerHelper(
      {required this.scrollController,
      this.fixedItemSize,
      this.onIndexChanged,
      this.anchorOffset});

  /// The [ScrollController] of the [ScrollView]
  final ScrollController scrollController;

  /// The fixed item size
  /// If the [ScrollView] scrolls along vertical, it should be the fixed height of the item
  /// If the [ScrollView] scrolls along horizontal, it should be the fixed width of the item
  final double? fixedItemSize;

  /// The offset to apply to the top of each item
  final double? anchorOffset;

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
  final IndexChanged? onIndexChanged;

  double _lastOffset = 0;
  void notifyIndexChanged() {
    // if the scroll behavior is triggered by user, notify index changed
    if (scrollController.hasClients &&
        scrollController.offset >= scrollController.position.minScrollExtent) {
      if (scrollController.offset < scrollController.position.maxScrollExtent ||
          (scrollController.offset ==
                  scrollController.position.maxScrollExtent &&
              _lastOffset < scrollController.position.maxScrollExtent)) {
        final index = _getCurrIndex();
        if (index != _currIndex) {
          _currIndex = index;
          onIndexChanged?.call(
              _currIndex,
              scrollController.position.userScrollDirection !=
                  ScrollDirection.idle);
        }
      }
    }

    if (scrollController.offset >= scrollController.position.minScrollExtent &&
        scrollController.offset <= scrollController.position.maxScrollExtent) {
      _lastOffset = scrollController.offset;
    }
  }

  int _getCurrIndex() {
    int? tmpIndex;
    for (final index in _itemMap.keys.toList()) {
      final RevealedOffset? revealedOffset = _getOffsetToReveal(index);
      if (revealedOffset == null) {
        continue;
      }

      final double totalOffset = _applyAnchorOffset(revealedOffset.offset);
      if (totalOffset <= scrollController.offset &&
          totalOffset + revealedOffset.rect.height > scrollController.offset) {
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
        if (scrollController.offset >
            revealedOffset.offset + revealedOffset.rect.height) {
          RevealedOffset? nextRevealedOffset = _getOffsetToReveal(index + 1);
          if (nextRevealedOffset != null) {
            if (scrollController.offset < nextRevealedOffset.offset) {
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
            if (scrollController.offset >
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
  Future<void> scrollToIndex(
      {required int index,
      double scrollSpeed = 2,
      Curve curve = Curves.linear}) async {
    assert(scrollSpeed > 0);

    if (!scrollController.hasClients) {
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
      await scrollController.animateTo(
          _applyAnchorOffset(scrollController.offset),
          duration: Duration(milliseconds: 1),
          curve: curve);
      _currIndex = _getCurrIndex();
    }

    _isScrollingToIndex = true;

    if (fixedItemSize != null) {
      // if the item size is fixed, the target offset is index * fixedItemSize
      final targetOffset = _applyAnchorOffset(index * fixedItemSize!);
      final int scrollTime =
          ((scrollController.offset - targetOffset).abs() / scrollSpeed)
              .round();
      final Duration duration = Duration(milliseconds: scrollTime);
      await scrollController.animateTo(targetOffset,
          duration: duration, curve: curve);
    } else {
      // if the item size is not fixed, there are two cases to consider.
      // 1. if the target index item is already in viewport, we can get the target offset directly
      // 2. if the target index item is not in viewport, we should scroll to the first or last item in
      //    the viewport. And then we will get some more items in the viewport which are closer to
      //    the target item. Repeat the above steps until the target item is in the viewport and then
      //    we can get its offset and scroll to it.
      if (_itemMap.containsKey(index)) {
        await _animateToIndexInViewport(index, scrollSpeed, curve);
      } else {
        int tmpIndex = _currIndex;
        while (!_itemMap.containsKey(index)) {
          final sortedKeys = _itemMap.keys.toList()
            ..sort((first, second) => first.compareTo(second));
          final targetIndex =
              (tmpIndex < index) ? sortedKeys.last : sortedKeys.first;
          if (targetIndex == tmpIndex) {
            break;
          }
          tmpIndex = targetIndex;
          double alignment = (tmpIndex < index) ? 1 : 0;
          await _animateToIndexInViewport(tmpIndex, scrollSpeed, curve,
              alignment: alignment);
          if (!_isScrollingToIndex) {
            // this scrolling is interrupted
            return;
          }
        }

        await _animateToIndexInViewport(index, scrollSpeed, curve);
      }

      // sometimes the offset of items may change, for example, the height of the item changes
      // after rebuild, which makes it cannot scroll to the index exactly. So, jump to the exact
      // offset in finally.
      final targetScrollOffset = _getScrollOffset(index);
      if (targetScrollOffset != null &&
          scrollController.offset != targetScrollOffset) {
        scrollController.jumpTo(_applyAnchorOffset(targetScrollOffset));
      }

      _currIndex = index;
      _isScrollingToIndex = false;
    }
  }

  /// Scroll to the index item which is already in the viewport
  Future<void> _animateToIndexInViewport(
      int index, double scrollSpeed, Curve curve,
      {double alignment = 0}) async {
    final double? targetOffset = _getScrollOffset(index, alignment: alignment);
    if (targetOffset == null) {
      return;
    }

    final double totalOffset = _applyAnchorOffset(targetOffset);
    final int scrollTime =
        ((scrollController.offset - totalOffset).abs() / scrollSpeed).ceil();
    final Duration duration = Duration(milliseconds: scrollTime);
    await scrollController.animateTo(totalOffset,
        duration: duration, curve: curve);
  }

  /// Get the scroll offset for the target index
  double? _getScrollOffset(int index, {double alignment = 0}) {
    final revealOffset = _getOffsetToReveal(index, alignment: alignment);
    if (revealOffset == null) {
      return null;
    }

    return revealOffset.offset.clamp(scrollController.position.minScrollExtent,
        scrollController.position.maxScrollExtent + (anchorOffset ?? 0));
  }

  /// Get the [RevealedOffset] to reveal the target index
  RevealedOffset? _getOffsetToReveal(int index, {double alignment = 0}) {
    RevealedOffset? offset;

    final context = _itemMap[index]?.context;
    if (context != null) {
      final renderBox = context.findRenderObject();
      final viewport = RenderAbstractViewport.of(renderBox);
      if (renderBox != null && viewport != null) {
        offset = viewport.getOffsetToReveal(renderBox, alignment);
      }
    }

    return offset;
  }

  /// Apply the anchor offset to the scroll offset
  double _applyAnchorOffset(double currentOffset) =>
      currentOffset - (anchorOffset ?? 0);
}

class AnchorScrollController extends ScrollController {
  AnchorScrollController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String? debugLabel,
    this.onIndexChanged,
    this.fixedItemSize,
    this.anchorOffset,
  }) : super(
            initialScrollOffset: initialScrollOffset,
            keepScrollOffset: keepScrollOffset,
            debugLabel: debugLabel) {
    _helper = AnchorScrollControllerHelper(
        scrollController: this,
        fixedItemSize: fixedItemSize,
        onIndexChanged: onIndexChanged,
        anchorOffset: anchorOffset);
  }

  final double? fixedItemSize;

  final IndexChanged? onIndexChanged;

  final double? anchorOffset;

  late final AnchorScrollControllerHelper _helper;

  void addItem(int index, AnchorItemWrapperState state) {
    _helper.addItem(index, state);
  }

  void removeItem(int index) {
    _helper.removeItem(index);
  }

  @override
  void notifyListeners() {
    _helper.notifyIndexChanged();

    super.notifyListeners();
  }

  Future<void> scrollToIndex(
      {required int index,
      double scrollSpeed = 2,
      Curve curve = Curves.linear}) async {
    await _helper.scrollToIndex(
        index: index, scrollSpeed: scrollSpeed, curve: curve);
  }
}
