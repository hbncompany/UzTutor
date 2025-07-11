import 'package:flutter/material.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactDeveloperScreen extends StatelessWidget {
  const ContactDeveloperScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.indigo,
        title: Text(localizations.translate('contactDeveloper')),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('contactTitle'),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.translate('contactText'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 30),
            ListTile(
              leading: Icon(Icons.email, color: Theme.of(context).primaryColor),
              title: Text(localizations.translate('contactEmail')),
              onTap: () => _launchUrl('mailto:hbncompanyofficials@gmail.com'),
            ),
            ListTile(
              leading: Icon(Icons.phone, color: Theme.of(context).primaryColor),
              title: Text(localizations.translate('contactPhone')),
              onTap: () => _launchUrl('tel:+998901234567(test)'),
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                localizations.translate('appName'),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            Center(
              child: Text(
                localizations.translate('developer'),
                selectionColor: Colors.blue,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
