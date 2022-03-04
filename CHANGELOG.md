## 0.1.0

* Initial Open Source release.

## 0.2.0

* Support the case with already existed ScrollController.
* Fix errors of the critical cases.

## 0.3.0

* `onIndexChanged` gets called regardless of how the index is changed and add a `userScroll` parameter for `onIndexChanged` to indicate whether is scrolling by user.

## 0.3.1

* Modify README.md

## 0.3.2

* Fix [issue #2](https://github.com/lucian1024/anchor_scroll_controller/issues/2):  When the height of item is very large which leads to only one item is in the viewport, it will fall to infinite loop. 