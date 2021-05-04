# Shimmer

Forked from [hnvn/flutter_shimmer](https://github.com/hnvn/flutter_shimmer).

A package provides an easy way to add shimmer effect in Flutter project.

Note: When using multiple synchronized shimmers, glares will start in the same position.
This is possible to end up with the following shape (where slash is a glare):
```
--/
-/
/
--/
-/
/
```

<p>
    <img src="https://github.com/hnvn/flutter_shimmer/blob/master/screenshots/loading_list.gif?raw=true"/>
    <img src="https://github.com/hnvn/flutter_shimmer/blob/master/screenshots/slide_to_unlock.gif?raw=true"/>
</p>

## How to use

```dart
import 'package:shimmer/shimmer.dart';

```

```dart
SizedBox(
  width: 200.0,
  height: 100.0,
  child: Shimmer.fromColors(
    baseColor: Colors.red,
    highlightColor: Colors.yellow,
    child: Text(
      'Shimmer',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 40.0,
        fontWeight:
        FontWeight.bold,
      ),
    ),
  ),
);

```
