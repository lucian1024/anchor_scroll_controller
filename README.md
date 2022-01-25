# flutter anchor_scroll_view

This package implement a ScrollController which supports anchor. That is,  AnchorScrollController supports to scroll to index and listen to index changed while scrolling by user.

## Features

- Scroll to index

  ![Screenshot](https://github.com/lucian1024/anchor_scroll_view/blob/main/docs/images/scroll_to_index.gif)

- Listen to index changed

  ![Screenshot](https://github.com/lucian1024/anchor_scroll_view/blob/main/docs/images/on_index_changed.gif)

## Getting Started

In the `pubspec.yaml` of your flutter project, add the following dependency:

```yaml
dependencies:
  ...
  anchor_scroll_view: <latest_version>
```

In your library add the following import:

```dart
import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:anchor_scroll_controller/anchor_scroll_wrapper.dart';
```

Initialize an AnchorScrollController object and use it as the ScrollController of ListView, and wrap the items in the ListView with AnchorItemWrapper

```dart
late final AnchorScrollController _scrollController;

@override
void initState() {
  super.initState();

  _scrollController = AnchorScrollController(
    onIndexChanged: (index) {
      _tabController?.animateTo(index);
    },
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("GeneralScrollViewWidget"),
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: length,
            itemBuilder: (context, index) => AnchorItemWrapper(
              key: ValueKey(index),
              index: index,
              controller: _scrollController,
              child: Container(
                height: 50.0 + Random().nextInt(50),
                color: Colors.primaries[index % Colors.primaries.length],
                alignment: Alignment.center,
                child: Text(index.toString(),
                            style: const TextStyle(fontSize: 24, color: Colors.black)),
              ),
            )
          ),
        ),
        ... // omit more code
      ],
    )
  );
```



