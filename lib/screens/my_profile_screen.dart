import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'package:repetitor_resurs/providers/user_provider.dart';
import 'edit_profile_screen.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final userProfile = userProvider.userProfile;
    final firebaseUser = userProvider.firebaseUser;

    // Фойдаланувчи маълумотлари йўқ бўлса, юклаш ёки хато хабари
    if (userProvider.isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(
        foregroundColor: Colors.indigo,
          title: Text(localizations.translate('myProfile')),
          centerTitle: true,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (firebaseUser == null || userProfile == null) {
      return Scaffold(
        appBar: AppBar(
        foregroundColor: Colors.indigo,
          title: Text(localizations.translate('myProfile')),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  localizations.translate('userNotFound'),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/auth');
                  },
                  child: Text(localizations.translate('loginRegisterTitle')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Фойдаланувчи профили мавжуд бўлса
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.indigo,
        title: Text(localizations.translate('myProfile')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  backgroundImage: userProfile.imageUrl != null &&
                          userProfile.imageUrl!.isNotEmpty
                      ? NetworkImage(userProfile.imageUrl!)
                      : null,
                  child: userProfile.imageUrl == null ||
                          userProfile.imageUrl!.isEmpty
                      ? Icon(Icons.person,
                          size: 80, color: Theme.of(context).primaryColor)
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  userProfile.name ?? localizations.translate('notAvailable'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColorDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${localizations.translate('emailLabel')} ${userProfile.email}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${localizations.translate('userTypeLabel')} ${localizations.translate('${userProfile.userType}')}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (userProfile.phoneNumber != null &&
                    userProfile.phoneNumber!.isNotEmpty)
                  Text(
                    '${localizations.translate('phoneNumberLabel')}: ${userProfile.phoneNumber}',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 30),
                // Профилни таҳрирлаш тугмаси (келажакда қўшиш мумкин)
                ElevatedButton.icon(
                  onPressed: () {
                    // Профилни таҳрирлаш логикаси
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const EditProfileScreen(), // Янги профил экранига навигация
                      ),
                    );
                  },
                  icon: Icon(Icons.edit),
                  label: Text('Профилни таҳрирлаш'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                    elevation: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
