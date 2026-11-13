import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import 'live_page.dart';
import 'photo_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    void open(Widget page) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => page));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle, style: theme.textTheme.headlineMedium),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.homeIntro, style: theme.textTheme.titleLarge),
            const SizedBox(height: 28),
            _BigButton(
              icon: Icons.center_focus_strong,
              label: l10n.homeLive,
              onPressed: () => open(const LivePage()),
            ),
            const SizedBox(height: 20),
            _BigButton(
              icon: Icons.photo_camera,
              label: l10n.homeTakePhoto,
              onPressed: () =>
                  open(const PhotoPage(source: ImageSource.camera)),
            ),
            const SizedBox(height: 20),
            _BigButton(
              icon: Icons.photo_library,
              label: l10n.homeGallery,
              onPressed: () =>
                  open(const PhotoPage(source: ImageSource.gallery)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(96),
        textStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      icon: Icon(icon, size: 40),
      label: Text(label),
    );
  }
}
