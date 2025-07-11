import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'package:repetitor_resurs/models/tutor.dart';
import 'package:repetitor_resurs/models/teaching_center.dart'; // TeachingCenter modelini import qilish
import 'package:repetitor_resurs/providers/user_provider.dart';

class TutorListScreen extends StatefulWidget {
  // teachingCenterId'ни қабул қилиш учун янги майдон
  final String? teachingCenterId;

  const TutorListScreen({super.key, this.teachingCenterId});

  @override
  State<TutorListScreen> createState() => _TutorListScreenState();
}

class _TutorListScreenState extends State<TutorListScreen> {
  String _searchTerm = '';
  int _filterRating = 0; // 0 = барча рейтинглар
  String? _selectedFilterRegion; // Танланган вилоят
  String? _selectedFilterDistrict; // Танланган туман
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
        child: _TutorFilterModal(
          initialSearchTerm: _searchTerm,
          initialFilterRating: _filterRating,
          initialSelectedRegion: _selectedFilterRegion,
          initialSelectedDistrict: _selectedFilterDistrict,
          uzbekistanRegions: uzbekistanRegions,
        ),
      ),
    );

    if (results != null) {
      setState(() {
        _searchTerm = results['searchTerm'];
        _filterRating = results['filterRating'];
        _selectedFilterRegion = results['selectedRegion'];
        _selectedFilterDistrict = results['selectedDistrict'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // Stream'ни teachingCenterId'га қараб ўзгартириш
    Stream<QuerySnapshot> tutorStream;
    if (widget.teachingCenterId != null) {
      // teachingCenterId'га уланган репетиторларни фильтрлаш
      tutorStream = _firestore
          .collection('tutors')
          .where('connectedTeachingCenterIds',
              arrayContains: widget.teachingCenterId)
          .snapshots();
    } else {
      tutorStream = _firestore.collection('tutors').snapshots();
    }

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.indigo,
        title: Text(
          widget.teachingCenterId != null
              ? localizations
                  .translate('connectedTutors') // Уланган репетиторлар
              : localizations
                  .translate('tutorsListTitle'), // Барча репетиторлар
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Агар teachingCenterId мавжуд бўлса, фильтр тугмасини яшириш
          if (widget.teachingCenterId == null)
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
              stream: tutorStream, // Ўзгартирилган стрим
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child:
                          Text(localizations.translate('errorLoadingTutors')));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text(localizations.translate('noTutorsFound')));
                }

                final allTutors = snapshot.data!.docs
                    .map((doc) => Tutor.fromFirestore(doc))
                    .toList();

                final filteredTutors = allTutors.where((tutor) {
                  // Агар teachingCenterId мавжуд бўлса, фақат унга уланган репетиторларни кўрсатиш
                  // Бу ҳолатда бошқа фильтрларни эътиборсиз қолдирамиз, чунки рўйхат аллақачон фильтрланган.
                  if (widget.teachingCenterId != null) {
                    return true; // Stream аллақачон фильтрлаган
                  }

                  final matchesSearch = tutor.subject
                          .toLowerCase()
                          .contains(_searchTerm.toLowerCase()) ||
                      tutor.name
                          .toLowerCase()
                          .contains(_searchTerm.toLowerCase());
                  final matchesRating = tutor.rating >= _filterRating;

                  // Агар teachingType 'offline' бўлса ва region/district танланмаган бўлса, ҳаммасини кўрсатиш
                  // Агар teachingType 'online' бўлса, region/district фильтрларини эътиборсиз қолдириш
                  final matchesRegion = _selectedFilterRegion == null ||
                      (tutor.teachingType == 'offline' &&
                          tutor.region == _selectedFilterRegion);
                  final matchesDistrict = _selectedFilterDistrict == null ||
                      (tutor.teachingType == 'offline' &&
                          tutor.district == _selectedFilterDistrict);

                  // Агар регион ёки туман танланган бўлса, фақат "offline" репетиторларни кўрсатиш
                  if (_selectedFilterRegion != null ||
                      _selectedFilterDistrict != null) {
                    return matchesSearch &&
                        matchesRating &&
                        matchesRegion &&
                        matchesDistrict &&
                        tutor.teachingType == 'offline';
                  }

                  return matchesSearch &&
                      matchesRating; // Акс ҳолда, барча турдаги репетиторларни кўрсатиш
                }).toList();

                if (filteredTutors.isEmpty) {
                  return Center(
                      child: Text(localizations.translate('noTutorsFound')));
                }

                return ListView.builder(
                  itemCount: filteredTutors.length,
                  itemBuilder: (context, index) {
                    final tutor = filteredTutors[index];
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
                              backgroundImage: tutor.imageUrl != null &&
                                      tutor.imageUrl!.isNotEmpty
                                  ? NetworkImage(tutor.imageUrl!)
                                  : null,
                              child: tutor.imageUrl == null ||
                                      tutor.imageUrl!.isEmpty
                                  ? Icon(Icons.person,
                                      size: 50,
                                      color: Theme.of(context).primaryColor)
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tutor.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tutor.subject,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 24),
                                Text(
                                  '${tutor.rating.toStringAsFixed(1)}/5',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: [
                                    Text(
                                      "${localizations.translate('price')}",
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green),
                                    ),
                                    Text(
                                      "${tutor.price.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (tutor.connectedTeachingCenterIds.isNotEmpty)
                              Text(
                                "${localizations.translate('connectedToCenter')}",
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xff113ea1)),
                              ),
                            // Уланган ўқув марказлари номини кўрсатиш
                            if (tutor.connectedTeachingCenterIds.isNotEmpty)
                              Column(
                                children: tutor.connectedTeachingCenterIds
                                    .map((centerId) {
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: _firestore
                                        .collection('teachingCenters')
                                        .doc(centerId)
                                        .get(),
                                    builder: (context, centerSnapshot) {
                                      if (centerSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Padding(
                                          padding: EdgeInsets.only(top: 8.0),
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        );
                                      }
                                      if (centerSnapshot.hasError ||
                                          !centerSnapshot.hasData ||
                                          !centerSnapshot.data!.exists) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            localizations.translate(
                                                'connectedToCenter',
                                                args: {
                                                  'centerName':
                                                      'Номаълум марказ'
                                                }),
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.redAccent),
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      }
                                      final teachingCenter =
                                          TeachingCenter.fromFirestore(
                                              centerSnapshot.data!);
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).pushNamed(
                                              '/teaching_center_profile',
                                              arguments: teachingCenter.id,
                                            );
                                          },
                                          child: Text(
                                            "${teachingCenter.name}",
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xff1594dc)),
                                          ),
                                          /*Text(
                                            teachingCenter.name,
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green),
                                            textAlign: TextAlign.center,
                                          ),*/
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    '/tutor_profile',
                                    arguments: tutor.id,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 5,
                                ),
                                child: Text(
                                    localizations.translate('viewProfile'),
                                    style: const TextStyle(fontSize: 16)),
                              ),
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
class _TutorFilterModal extends StatefulWidget {
  final String initialSearchTerm;
  final int initialFilterRating;
  final String? initialSelectedRegion;
  final String? initialSelectedDistrict;
  final Map<String, List<String>> uzbekistanRegions;

  const _TutorFilterModal({
    super.key,
    required this.initialSearchTerm,
    required this.initialFilterRating,
    this.initialSelectedRegion,
    this.initialSelectedDistrict,
    required this.uzbekistanRegions,
  });

  @override
  State<_TutorFilterModal> createState() => _TutorFilterModalState();
}

class _TutorFilterModalState extends State<_TutorFilterModal> {
  late TextEditingController _searchController;
  late int _currentFilterRating;
  late String? _currentSelectedRegion;
  late String? _currentSelectedDistrict;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchTerm);
    _currentFilterRating = widget.initialFilterRating;
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
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: localizations.translate('allRatings'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            value: _currentFilterRating,
            items: [
              DropdownMenuItem(
                  value: 0, child: Text(localizations.translate('allRatings'))),
              for (int i = 1; i <= 5; i++)
                DropdownMenuItem(
                    value: i,
                    child: Text(localizations
                        .translate('ratingAbove', args: {'rating': i}))),
            ],
            onChanged: (value) {
              setState(() {
                _currentFilterRating = value!;
              });
            },
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
                      'filterRating': _currentFilterRating,
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
