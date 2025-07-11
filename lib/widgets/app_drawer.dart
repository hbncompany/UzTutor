import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'package:repetitor_resurs/providers/app_language_provider.dart';
import 'package:repetitor_resurs/providers/app_theme_provider.dart';
import 'package:repetitor_resurs/providers/user_provider.dart';
import 'package:repetitor_resurs/screens/my_profile_screen.dart';
import 'package:repetitor_resurs/models/user_profile.dart'; // UserProfile'ни импорт қилиш

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final appLanguage = Provider.of<AppLanguageProvider>(context);
    final appTheme = Provider.of<AppThemeProvider>(context);

    final User? firebaseUser = userProvider.firebaseUser;
    final UserProfile? userProfile =
        userProvider.userProfile; // UserProfile'ни олиш
    print(userProvider.userProfile);

    String displayName = firebaseUser?.isAnonymous == true
        ? 'Меҳмон'
        : userProfile?.name ?? firebaseUser?.email ?? 'Номаълум фойдаланувчи';
    String userType = localizations.translate(
        '${userProfile?.userType}'); // userProfile?.userType ?? 'Номаълум';
    String displayEmail = firebaseUser?.isAnonymous == true
        ? 'Аноним'
        : userProfile?.email ?? firebaseUser?.email ?? 'Мавжуд эмас';
    String displayPhone = userProfile?.phoneNumber ?? 'Мавжуд эмас';
    String? profileImageUrl = userProfile?.imageUrl;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .scaffoldBackgroundColor, // Фон рангини ўзгартирдик
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              accountEmail: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${localizations.translate('userTypeLabel')} $userType',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '${localizations.translate('phoneNumberLabel')} $displayPhone',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white, // Аватар учун чегара
                    width: 2.0,
                  ),
                ),
                child: CircleAvatar(
                  radius: 45, // Радиусни катталаштирдик
                  backgroundColor:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  backgroundImage:
                      profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                  child: profileImageUrl == null || profileImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).colorScheme.secondary
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person,
              title: localizations.translate('myProfile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyProfileScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.language,
              title: localizations.translate('appLanguage'),
              trailing: DropdownButton<Locale>(
                value: appLanguage.appLocale,
                onChanged: (Locale? newLocale) {
                  if (newLocale != null) {
                    appLanguage.changeLanguage(newLocale);
                  }
                },
                items: AppLocalizations.supportedLocales.map((Locale locale) {
                  return DropdownMenuItem<Locale>(
                    value: locale,
                    child: Text(
                      locale.languageCode == 'uz'
                          ? localizations.translate('uzbek')
                          : locale.languageCode == 'ru'
                              ? localizations.translate('russian')
                              : localizations.translate('english'),
                    ),
                  );
                }).toList(),
              ),
            ),
            _buildDrawerItem(
              context,
              icon: appTheme.themeMode == ThemeMode.light
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode,
              title: localizations.translate('appTheme'),
              trailing: Switch(
                inactiveTrackColor: Colors.orange,
                value: appTheme.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  appTheme.toggleTheme();
                },
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.contact_support,
              title: localizations.translate('contactDeveloper'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/contact');
              },
            ),
            const Divider(
                height: 30,
                thickness: 1.5,
                indent: 20,
                endIndent: 20), // Яхшироқ ажратувчи
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: localizations.translate('logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/auth');
              },
              textColor: Colors.redAccent, // Чиқиш тугмаси учун қизил ранг
              iconColor: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 10.0, vertical: 5.0), // Горизонтал ва вертикал padding
      child: Card(
        elevation: 4, // Карточкага соя
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)), // Думалоқ бурчаклар
        child: ListTile(
          leading:
              Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          trailing: trailing,
          onTap: onTap,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  15)), // ListTile учун ҳам думалоқ бурчаклар
          tileColor: Theme.of(context).cardColor, // Карточканинг фон ранги
        ),
      ),
    );
  }
}
