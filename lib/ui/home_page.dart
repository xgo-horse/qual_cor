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
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.homeIntro, style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            _BigButton(
              icon: Icons.center_focus_strong,
              label: l10n.homeLive,
              onPressed: () => open(const LivePage()),
            ),
            const SizedBox(height: 12),
            _BigButton(
              icon: Icons.photo_camera,
              label: l10n.homeTakePhoto,
              onPressed: () =>
                  open(const PhotoPage(source: ImageSource.camera)),
            ),
            const SizedBox(height: 12),
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
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 24),
      label: Text(label),
    );
  }
}
