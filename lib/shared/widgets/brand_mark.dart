import 'package:flutter/widgets.dart';

import '../../core/theme/app_text_styles.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) =>
      const Text('VAMPIOR', style: AppTextStyles.brand, semanticsLabel: 'Vampior');
}
