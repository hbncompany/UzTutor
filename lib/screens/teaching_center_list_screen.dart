import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'package:repetitor_resurs/models/teaching_center.dart';
import 'package:repetitor_resurs/providers/user_provider.dart';
import 'package:repetitor_resurs/screens/tutor_list_screen.dart'; // Репетиторлар рўйхатига ўтиш учун
import 'package:repetitor_resurs/models/request.dart'; // Request modelini import qilish

class TeachingCenterListScreen extends StatefulWidget {
  const TeachingCenterListScreen({super.key});

  @override
  State<TeachingCenterListScreen> createState() =>
      _TeachingCenterListScreenState();
}

class _TeachingCenterListScreenState extends State<TeachingCenterListScreen> {
  String _searchTerm = '';
  String? _selectedFilterRegion;
  String? _selectedFilterDistrict;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ўзбекистон вилоятлари ва туманлари
  final Map<String, List<String>> uzbekistanRegions = {
    'Toshkent Shahri': [
      'Chilonzor',
      'Yunusobod',
      'Mirzo Ulugbek',
      'Shayxontohur',
      'Sergeli',
      'Olmazor',
      'Uchtepa',
      'Yakkasaroy',
      'Bektemir',
      'Mirobod'
    ],
    'Toshkent Viloyati': [
      'Angren',
      'Bekobod',
      'Chirchiq',
      'Olmaliq',
      'Yangiyoʻl',
      'Gʻazalkent',
      'Keles',
      'Parkent',
      'Piskent',
      'Qibray',
      'Ohangaron',
      'Boʻka',
      'Oqqoʻrgʻon',
      'Chinoz',
      'Yuqori Chirchiq'
    ],
    'Samarqand Viloyati': [
      'Samarqand Shahri',
      'Kattaqoʻrgʻon',
      'Bulungʻur',
      'Jomboy',
      'Ishtixon',
      'Narpay',
      'Oqdaryo',
      'Pastdargʻom',
      'Paxtachi',
      'Toyloq',
      'Urgut',
      'Qoʻshrabot'
    ],
    'Andijon Viloyati': [
      'Andijon Shahri',
      'Asaka',
      'Xonobod',
      'Qoʻrgʻontepa',
      'Marxamat',
      'Paxtaobod',
      'Ulugʻnor',
      'Andijon',
      'Buloqboshi',
      'Izboskan',
      'Jalolquduq',
      'Oltinkoʻl',
      'Shahrixon'
    ],
    'Fargʻona Viloyati': [
      'Fargʻona Shahri',
      'Qoʻqon',
      'Margʻilon',
      'Quvasoy',
      'Beshariq',
      'Bogʻdod',
      'Buvayda',
      'Dangʻara',
      'Fargʻona',
      'Furqat',
      'Oltiariq',
      'Qoʻshtepa',
      'Rishton',
      'Soʻx',
      'Toshloq',
      'Uchkoʻprik',
      'Yozyovon'
    ],
    'Namangan Viloyati': [
      'Namangan Shahri',
      'Chust',
      'Pop',
      'Toʻraqoʻrgʻon',
      'Kosonsoy',
      'Mingbuloq',
      'Norin',
      'Uchqoʻrgʻon',
      'Uychi',
      'Yangiqoʻrgʻon',
      'Namangan'
    ],
    'Buxoro Viloyati': [
      'Buxoro Shahri',
      'Gʻijduvon',
      'Kogon',
      'Shofirkon',
      'Jondor',
      'Olot',
      'Peshku',
      'Qorakoʻl',
      'Romitan',
      'Vobkent',
      'Buxoro'
    ],
    'Xorazm Viloyati': [
      'Urganch Shahri',
      'Xiva',
      'Hazorasp',
      'Bogʻot',
      'Gurlan',
      'Qoʻshkoʻpir',
      'Shovot',
      'Urganch',
      'Xonqa',
      'Yangibozor',
      'Yangiobod'
    ],
    'Qashqadaryo Viloyati': [
      'Qarshi Shahri',
      'Shahrisabz',
      'Kitob',
      'Gʻuzor',
      'Dehqonobod',
      'Kasbi',
      'Muborak',
      'Nishon',
      'Qamashi',
      'Qarshi',
      'Chiroqchi',
      'Koson',
      'Mirishkor',
      'Yakkabogʻ'
    ],
    'Surxondaryo Viloyati': [
      'Termiz Shahri',
      'Denov',
      'Boysun',
      'Sherobod',
      'Angor',
      'Jarqoʻrgʻon',
      'Qiziriq',
      'Qumqoʻrgʻon',
      'Muzrabod',
      'Oltinsoy',
      'Sariosiyo',
      'Termiz',
      'Uzun'
    ],
    'Jizzax Viloyati': [
      'Jizzax Shahri',
      'Gagarin',
      'Doʻstlik',
      'Zomin',
      'Arnasoy',
      'Baxmal',
      'Forish',
      'Sharof Rashidov',
      'Mirzachoʻl',
      'Paxtakor',
      'Yangiobod'
    ],
    'Sirdaryo Viloyati': [
      'Guliston Shahri',
      'Yangiyer',
      'Shirino',
      'Sirdaryo',
      'Boyovut',
      'Guliston',
      'Oqoltin',
      'Saʼdullayev',
      'Xovos',
      'Mirzaobod'
    ],
    'Navoiy Viloyati': [
      'Navoiy Shahri',
      'Zarafshon',
      'Uchquduq',
      'Konimex',
      'Navbahor',
      'Qiziltepa',
      'Tomdi',
      'Xatirchi'
    ],
    'Qoraqalpogʻiston Respublikasi': [
      'Nukus Shahri',
      'Beruniy',
      'Chimboy',
      'Qoʻngʻirot',
      'Amudaryo',
      'Kegeyli',
      'Moʻynoq',
      'Qonlikoʻl',
      'Shumanay',
      'Taxtakoʻpir',
      'Toʻrtkoʻl',
      'Xoʻjayli',
      'Ellikqalʼa'
    ],
  };

  void _showFilterModal() async {
    final localizations = AppLocalizations.of(context);
    final results = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _TeachingCenterFilterModal(
          initialSearchTerm: _searchTerm,
          initialSelectedRegion: _selectedFilterRegion,
          initialSelectedDistrict: _selectedFilterDistrict,
          uzbekistanRegions: uzbekistanRegions,
        ),
      ),
    );

    if (results != null) {
      setState(() {
        _searchTerm = results['searchTerm'];
        _selectedFilterRegion = results['selectedRegion'];
        _selectedFilterDistrict = results['selectedDistrict'];
      });
    }
  }

  Future<void> _sendRequest(BuildContext context, TeachingCenter center) async {
    final localizations = AppLocalizations.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.firebaseUser?.uid;

    if (currentUserId == null ||
        userProvider.userProfile?.userType != 'tutor') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.translate('loginRequiredReview'))),
      );
      return;
    }

    try {
      // Репетиторнинг юборган сўровлари сонини текшириш
      final tutorRequests = await _firestore
          .collection('requests')
          .where('tutorId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      // Максимал сўровлар сонини 5 га ўзгартириш
      if (tutorRequests.docs.length >= 5) {
        // O'zgartirildi: 3 -> 5
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(localizations.translate('maxRequestsReached'))),
        );
        return;
      }

      // Аллқачон сўров юборилганми?
      final existingRequest = await _firestore
          .collection('requests')
          .where('tutorId', isEqualTo: currentUserId)
          .where('teachingCenterId', isEqualTo: center.id)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(localizations.translate('requestAlreadySent'))),
        );
        return;
      }

      // Янги сўров яратиш
      await _firestore.collection('requests').add({
        'tutorId': currentUserId,
        'teachingCenterId': center.id,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.translate('requestSentSuccess'))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizations.translate('errorProcessingRequest',
                args: {'error': e.toString()}))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final bool isTutor = userProvider.userProfile?.userType == 'tutor';

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.indigo,
        title: Text(localizations.translate('findTeachingCenters')),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showFilterModal,
                icon: const Icon(Icons.filter_list),
                label: Text(localizations.translate('filterButton'),
                    style: const TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 5,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('teachingCenters').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text(localizations.translate(
                          'errorLoadingTutors'))); // Умумий хато хабари
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text(localizations
                          .translate('noTeachingCentersFound'))); // Янги хабар
                }

                final allCenters = snapshot.data!.docs
                    .map((doc) => TeachingCenter.fromFirestore(doc))
                    .toList();

                final filteredCenters = allCenters.where((center) {
                  final matchesSearch = center.name
                          .toLowerCase()
                          .contains(_searchTerm.toLowerCase()) ||
                      center.description
                          .toLowerCase()
                          .contains(_searchTerm.toLowerCase());

                  bool matchesLocation = true;
                  if (_selectedFilterRegion != null) {
                    matchesLocation = center.locations
                        .any((loc) => loc.region == _selectedFilterRegion);
                  }
                  if (_selectedFilterDistrict != null) {
                    matchesLocation = matchesLocation &&
                        center.locations.any(
                            (loc) => loc.district == _selectedFilterDistrict);
                  }

                  return matchesSearch && matchesLocation;
                }).toList();

                if (filteredCenters.isEmpty) {
                  return Center(
                      child: Text(
                          localizations.translate('noTeachingCentersFound')));
                }

                return ListView.builder(
                  itemCount: filteredCenters.length,
                  itemBuilder: (context, index) {
                    final center = filteredCenters[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.2),
                              backgroundImage: center.imageUrl != null &&
                                      center.imageUrl!.isNotEmpty
                                  ? NetworkImage(center.imageUrl!)
                                  : null,
                              child: center.imageUrl == null ||
                                      center.imageUrl!.isEmpty
                                  ? Icon(Icons.school,
                                      size: 50,
                                      color: Theme.of(context).primaryColor)
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              center.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              center.description.length > 100
                                  ? '${center.description.substring(0, 100)}...'
                                  : center.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              localizations.translate('tutorsConnected', args: {
                                'count': center.connectedTutorIds.length
                              }),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                            const SizedBox(height: 16),
                            // Жойлашувларни кўрсатиш
                            if (center.locations.isNotEmpty)
                              Column(
                                children: center.locations
                                    .map((loc) => Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                size: 20,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                '${loc.region}, ${loc.district}${loc.locationTip != null ? ' (${loc.locationTip})' : ''}',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700]),
                                              ),
                                            ),
                                          ],
                                        ))
                                    .toList(),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Фақат ушбу марказга уланган репетиторларни кўрсатиш
                                      Navigator.of(context).pushNamed(
                                        '/tutor_list',
                                        arguments: {
                                          'teachingCenterId': center.id
                                        },
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      elevation: 5,
                                    ),
                                    child: Text(
                                      localizations.translate('viewTutors'),
                                      style: const TextStyle(fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                if (isTutor) // Фақат репетиторлар сўров юбора олади
                                  const SizedBox(width: 10),
                                if (isTutor)
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _sendRequest(context, center),
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        elevation: 5,
                                      ),
                                      child: Text(
                                          localizations
                                              .translate('sendRequest'),
                                          style: const TextStyle(fontSize: 16)),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Фильтр модали учун янги виджет
class _TeachingCenterFilterModal extends StatefulWidget {
  final String initialSearchTerm;
  final String? initialSelectedRegion;
  final String? initialSelectedDistrict;
  final Map<String, List<String>> uzbekistanRegions;

  const _TeachingCenterFilterModal({
    super.key,
    required this.initialSearchTerm,
    this.initialSelectedRegion,
    this.initialSelectedDistrict,
    required this.uzbekistanRegions,
  });

  @override
  State<_TeachingCenterFilterModal> createState() =>
      _TeachingCenterFilterModalState();
}

class _TeachingCenterFilterModalState
    extends State<_TeachingCenterFilterModal> {
  late TextEditingController _searchController;
  late String? _currentSelectedRegion;
  late String? _currentSelectedDistrict;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchTerm);
    _currentSelectedRegion = widget.initialSelectedRegion;
    _currentSelectedDistrict = widget.initialSelectedDistrict;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              localizations.translate('filterButton'),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 30),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: localizations.translate('searchHint'),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: localizations.translate('filterByRegion'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            value: _currentSelectedRegion,
            hint: Text(localizations.translate('selectRegion')),
            items: [
              DropdownMenuItem(
                  value: null,
                  child: Text(localizations.translate('allRegions'))),
              ...widget.uzbekistanRegions.keys.map((String region) {
                return DropdownMenuItem<String>(
                  value: region,
                  child: Text(region),
                );
              }).toList(),
            ],
            onChanged: (String? newValue) {
              setState(() {
                _currentSelectedRegion = newValue;
                _currentSelectedDistrict =
                    null; // Вилоят ўзгарса, туманни тозалаш
              });
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: localizations.translate('filterByDistrict'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            value: _currentSelectedDistrict,
            hint: Text(localizations.translate('selectDistrict')),
            items: [
              DropdownMenuItem(
                  value: null,
                  child: Text(localizations.translate('allDistricts'))),
              if (_currentSelectedRegion != null)
                ...widget.uzbekistanRegions[_currentSelectedRegion!]!
                    .map((String district) {
                  return DropdownMenuItem<String>(
                    value: district,
                    child: Text(district),
                  );
                }).toList(),
            ],
            onChanged: (String? newValue) {
              setState(() {
                _currentSelectedDistrict = newValue;
              });
            },
            //enabled: _currentSelectedRegion != null,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'searchTerm': _searchController.text,
                      'selectedRegion': _currentSelectedRegion,
                      'selectedDistrict': _currentSelectedDistrict,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 5,
                  ),
                  child: Text(localizations.translate('applyFilters')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'searchTerm': '',
                      'selectedRegion': null,
                      'selectedDistrict': null,
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Text(localizations.translate('clearFilters')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
