import 'package:flutter/widgets.dart';

/// 3×3 colour-block illustration that fills its box.
class SlideArt extends StatelessWidget {
  const SlideArt({super.key, required this.cells});
  final List<int> cells;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        children: [
          for (var r = 0; r < 3; r++)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = 0; c < 3; c++)
                    Expanded(child: ColoredBox(color: Color(cells[r * 3 + c]))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
