import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'licenses.dart';
import 'warhammer_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerLicenses();
  warhammer.store = ModeStore.platformDefault();
  await warhammer.restore();
  runApp(const QualCorApp());
}
