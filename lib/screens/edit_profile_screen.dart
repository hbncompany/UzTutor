import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'package:repetitor_resurs/providers/user_provider.dart';
import 'package:repetitor_resurs/models/user_profile.dart';
import 'package:repetitor_resurs/models/tutor.dart'; // Tutor modelini import qilish
import 'package:repetitor_resurs/models/teaching_center.dart'; // TeachingCenter modelini import qilish
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore'ni import qilish
import 'package:image_picker/image_picker.dart'; // Image picker учун
import 'dart:io'; // File учун

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _imageUrlController;

  // Репетитор учун қўшимча контроллерлар ва ҳолатлар
  late TextEditingController _subjectController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationTipController;
  String _teachingType = 'online';
  String? _selectedRegion;
  String? _selectedDistrict;
  File? _pickedImage; // Танланган расм файли

  // Ўқув маркази учун қўшимча контроллерлар ва ҳолатлар
  late TextEditingController _centerNameController;
  List<TeachingCenterLocation> _centerLocations = []; // Бир нечта жойлашувлар

  String? _message;
  bool _isMessageError = false;
  bool _isLoading = false;
  bool _isLoadingUserData =
      true; // Фойдаланувчига хос маълумотларни юклаш ҳолати
  Tutor? _currentTutor; // Жорий репетитор маълумотлари
  TeachingCenter? _currentTeachingCenter; // Жорий ўқув маркази маълумотлари

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

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userProfile = userProvider.userProfile;

    _nameController = TextEditingController(text: userProfile?.name ?? '');
    _phoneController =
        TextEditingController(text: userProfile?.phoneNumber ?? '');
    _imageUrlController =
        TextEditingController(text: userProfile?.imageUrl ?? '');

    // Репетитор ва ўқув маркази учун контроллерларни инициализация қилиш
    _subjectController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationTipController = TextEditingController();
    _centerNameController = TextEditingController();

    // Агар фойдаланувчи репетитор бўлса, репетитор маълумотларини юклаш
    if (userProfile?.userType == 'tutor' && userProvider.firebaseUser != null) {
      _loadTutorData(userProvider.firebaseUser!.uid);
    }
    // Агар фойдаланувчи ўқув маркази бўлса, ўқув маркази маълумотларини юклаш
    else if (userProfile?.userType == 'teaching_center' &&
        userProvider.firebaseUser != null) {
      _loadCenterData(userProvider.firebaseUser!.uid);
    } else {
      _isLoadingUserData = false; // Репетитор ёки марказ бўлмаса, юклаш тугади
    }
  }

  Future<void> _loadTutorData(String uid) async {
    try {
      DocumentSnapshot tutorDoc =
          await FirebaseFirestore.instance.collection('tutors').doc(uid).get();
      if (tutorDoc.exists) {
        _currentTutor = Tutor.fromFirestore(tutorDoc);
        _subjectController.text = _currentTutor!.subject;
        _priceController.text = _currentTutor!.price.toString();
        _descriptionController.text = _currentTutor!.description;
        _teachingType = _currentTutor!.teachingType;
        _selectedRegion = _currentTutor!.region;
        _selectedDistrict = _currentTutor!.district;
        _locationTipController.text = _currentTutor!.locationTip ?? '';
      }
    } catch (e) {
      print("Репетитор маълумотларини юклашда хато: $e");
    } finally {
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  Future<void> _loadCenterData(String uid) async {
    try {
      DocumentSnapshot centerDoc = await FirebaseFirestore.instance
          .collection('teachingCenters')
          .doc(uid)
          .get();
      if (centerDoc.exists) {
        _currentTeachingCenter = TeachingCenter.fromFirestore(centerDoc);
        _centerNameController.text = _currentTeachingCenter!.name;
        _descriptionController.text = _currentTeachingCenter!.description;
        _centerLocations =
            List.from(_currentTeachingCenter!.locations); // Нусха олиш
        // Телефон рақами ва расм URL'и UserProfile'дан келади, шунинг учун улар аллақачон инициализация қилинган
      }
    } catch (e) {
      print("Ўқув маркази маълумотларини юклашда хато: $e");
    } finally {
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _imageUrlController.dispose();
    _subjectController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationTipController.dispose();
    _centerNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImageFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedImageFile != null) {
      setState(() {
        _pickedImage = File(pickedImageFile.path);
        _imageUrlController.text =
            ''; // Агар расм танланса, URL майдонини тозалаш
      });
    }
  }

  Future<void> _saveProfile(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final firebaseUser = userProvider.firebaseUser;

    if (firebaseUser == null || firebaseUser.isAnonymous) {
      setState(() {
        _message = localizations.translate('guestUserCannotEdit');
        _isMessageError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _isMessageError = false;
    });

    try {
      // Фойдаланувчи профилини янгилаш (users collection)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .update({
        'name': userProvider.userProfile?.userType == 'teaching_center' &&
                _centerNameController.text.trim().isNotEmpty
            ? _centerNameController.text.trim()
            : null,
        'centerName': userProvider.userProfile?.userType == 'teaching_center' &&
                _centerNameController.text.trim().isNotEmpty
            ? _centerNameController.text.trim()
            : null,
        'phoneNumber': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'imageUrl': _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : (_pickedImage != null
                ? 'https://placehold.co/150x150/A78BFA/ffffff?text=User' // Placeholder for picked image
                : null),
      });

      // Агар фойдаланувчи репетитор бўлса, репетитор профилини ҳам янгилаш
      if (userProvider.userProfile?.userType == 'tutor') {
        await FirebaseFirestore.instance
            .collection('tutors')
            .doc(firebaseUser.uid)
            .update({
          'name': _nameController.text.trim(), // Репетитор номи ҳам янгиланади
          'subject': _subjectController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'description': _descriptionController.text.trim(),
          'teachingType': _teachingType,
          'region': _selectedRegion,
          'district': _selectedDistrict,
          'locationTip': _locationTipController.text.trim().isEmpty
              ? null
              : _locationTipController.text.trim(),
          // connectedTeachingCenterIds бу ерда янгиланмайди, у сўровлар орқали бошқарилади
        });
      }
      // Агар фойдаланувчи ўқув маркази бўлса, ўқув маркази профилини ҳам янгилаш
      else if (userProvider.userProfile?.userType == 'teaching_center') {
        await FirebaseFirestore.instance
            .collection('teachingCenters')
            .doc(firebaseUser.uid)
            .update({
          'name': _centerNameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'locations': _centerLocations.map((loc) => loc.toMap()).toList(),
        });
      }

      // UserProvider'даги профилни янгилаш
      await userProvider
          .setUser(firebaseUser); // Бу _loadUserProfile'ни чақиради

      setState(() {
        _message = localizations.translate('profileUpdateSuccess');
        _isMessageError = false;
      });
      // Муваффақиятли янгилангандан сўнг орқага қайтиш
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop();
      });
    } catch (e) {
      setState(() {
        _message = localizations
            .translate('profileUpdateError', args: {'error': e.toString()});
        _isMessageError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Жойлашув қўшиш диалоги
  Future<TeachingCenterLocation?> _showAddLocationDialog(
      BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    String? tempRegion;
    String? tempDistrict;
    String tempLocationTip = '';
    final _locationFormKey = GlobalKey<FormState>();

    return showDialog<TeachingCenterLocation>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(localizations.translate('addLocation')),
              content: SingleChildScrollView(
                child: Form(
                  key: _locationFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: localizations.translate('selectRegion'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        value: tempRegion,
                        hint: Text(localizations.translate('selectRegion')),
                        items: uzbekistanRegions.keys.map((String region) {
                          return DropdownMenuItem<String>(
                            value: region,
                            child: Text(region),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            tempRegion = newValue;
                            tempDistrict = null;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Вилоятни танлаш мажбурий.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: localizations.translate('selectDistrict'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        value: tempDistrict,
                        hint: Text(localizations.translate('selectDistrict')),
                        items: tempRegion != null
                            ? uzbekistanRegions[tempRegion!]!
                                .map((String district) {
                                return DropdownMenuItem<String>(
                                  value: district,
                                  child: Text(district),
                                );
                              }).toList()
                            : [],
                        onChanged: (String? newValue) {
                          setState(() {
                            tempDistrict = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Туманни танлаш мажбурий.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText:
                              localizations.translate('locationTipLabel'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (value) {
                          tempLocationTip = value;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(localizations.translate('cancelButton')),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: Text(localizations.translate('addLocation')),
                  onPressed: () {
                    if (_locationFormKey.currentState!.validate()) {
                      Navigator.of(dialogContext).pop(
                        TeachingCenterLocation(
                          region: tempRegion!,
                          district: tempDistrict!,
                          locationTip: tempLocationTip.isNotEmpty
                              ? tempLocationTip
                              : null,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final userProfile = userProvider.userProfile;
    final firebaseUser = userProvider.firebaseUser;

    // Умумий юклаш ҳолати
    if (userProvider.isLoadingProfile || _isLoadingUserData) {
      return Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.indigo,
          title: Text(localizations.translate('editProfile')),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(localizations.translate('loadingProfileData')),
            ],
          ),
        ),
      );
    }

    if (firebaseUser == null || firebaseUser.isAnonymous) {
      return Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.indigo,
          title: Text(localizations.translate('editProfile')),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  localizations.translate('guestUserCannotEdit'),
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

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.indigo,
        title: Text(localizations.translate('editProfile')),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.2),
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider<Object>?
                          : (_imageUrlController.text.isNotEmpty
                              ? NetworkImage(_imageUrlController.text)
                              : (userProfile?.imageUrl != null &&
                                      userProfile!.imageUrl!.isNotEmpty
                                  ? NetworkImage(userProfile.imageUrl!)
                                  : null)),
                      child: (_pickedImage == null &&
                              _imageUrlController.text.isEmpty &&
                              (userProfile?.imageUrl == null ||
                                  userProfile!.imageUrl!.isEmpty))
                          ? Icon(Icons.person,
                              size: 60, color: Theme.of(context).primaryColor)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: Text(
                            localizations.translate('selectImageFromGallery')),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _imageUrlController,
                          decoration: InputDecoration(
                            labelText: localizations.translate('enterImageUrl'),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          keyboardType: TextInputType.url,
                          onChanged: (value) {
                            setState(() {
                              _pickedImage =
                                  null; // URL киритилса, танланган расмни тозалаш
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    localizations.translate('emailLabel'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    userProfile?.email ??
                        localizations.translate('notAvailable'),
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizations.translate('userTypeLabel'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    localizations.translate('${userProfile?.userType}') ??
                        localizations.translate('notAvailable'),
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Фойдаланувчи турига қараб майдонларни кўрсатиш
                  if (userProfile?.userType == 'client')
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('fullNameLabel'),
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 3) {
                          return 'Исм камида 3 белгидан иборат бўлиши керак.';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 12),
                  // Телефон рақами барча турлар учун умумий
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: localizations.translate('phoneNumberLabel'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length < 9) {
                        return 'Телефон рақами тўғри киритилмаган.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Репетитор учун қўшимча майдонлар
                  if (userProfile?.userType == 'tutor') ...[
                    const Divider(height: 30),
                    Text(
                      localizations.translate('updateProfile'),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController, // Репетитор учун ҳам исм
                      decoration: InputDecoration(
                        labelText: localizations.translate('fullNameLabel'),
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Исм киритиш мажбурий.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('subjectLabel'),
                        prefixIcon: const Icon(Icons.book),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Фан киритиш мажбурий.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('priceLabel'),
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Нархни тўғри киритинг.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('descriptionLabel'),
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Тавсиф киритиш мажбурий.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(localizations.translate('teachingTypeLabel'),
                            style: Theme.of(context).textTheme.titleMedium),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text(
                                    localizations.translate('onlineTeaching')),
                                value: 'online',
                                groupValue: _teachingType,
                                onChanged: (value) {
                                  setState(() {
                                    _teachingType = value!;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text(
                                    localizations.translate('offlineTeaching')),
                                value: 'offline',
                                groupValue: _teachingType,
                                onChanged: (value) {
                                  setState(() {
                                    _teachingType = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_teachingType == 'offline')
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText:
                                  localizations.translate('selectRegion'),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            value: _selectedRegion,
                            hint: Text(localizations.translate('selectRegion')),
                            items: uzbekistanRegions.keys.map((String region) {
                              return DropdownMenuItem<String>(
                                value: region,
                                child: Text(region),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedRegion = newValue;
                                _selectedDistrict =
                                    null; // Вилоят ўзгарса, туманни тозалаш
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Вилоятни танлаш мажбурий.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText:
                                  localizations.translate('selectDistrict'),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            value: _selectedDistrict,
                            hint:
                                Text(localizations.translate('selectDistrict')),
                            items: _selectedRegion != null
                                ? uzbekistanRegions[_selectedRegion!]!
                                    .map((String district) {
                                    return DropdownMenuItem<String>(
                                      value: district,
                                      child: Text(district),
                                    );
                                  }).toList()
                                : [],
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedDistrict = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Туманни танлаш мажбурий.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _locationTipController,
                            decoration: InputDecoration(
                              labelText:
                                  localizations.translate('locationTipLabel'),
                              prefixIcon: const Icon(Icons.location_on),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                  ]
                  // Ўқув маркази учун қўшимча майдонлар
                  else if (userProfile?.userType == 'teaching_center') ...[
                    const Divider(height: 30),
                    Text(
                      localizations.translate('updateProfile'),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _centerNameController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('centerNameLabel'),
                        prefixIcon: const Icon(Icons.school),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Марказ номи киритиш мажбурий.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('descriptionLabel'),
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Тавсиф киритиш мажбурий.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(localizations.translate('locationsLabel'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _centerLocations.length,
                      itemBuilder: (context, index) {
                        final loc = _centerLocations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text('${loc.region}, ${loc.district}'),
                            subtitle: Text(loc.locationTip ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _centerLocations.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final newLocation =
                            await _showAddLocationDialog(context);
                        if (newLocation != null) {
                          setState(() {
                            _centerLocations.add(newLocation);
                          });
                        }
                      },
                      icon: const Icon(Icons.add_location),
                      label: Text(localizations.translate('addLocation')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Харитадан жой танлаш учун placeholder
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Харитадан жой танлаш функцияси тез орада қўшилади!')),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: Text('Харитадан жой танлаш (Тез орада)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.grey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isMessageError
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _isMessageError
                                  ? Colors.red.shade400
                                  : Colors.green.shade400),
                        ),
                        child: Text(
                          _message!,
                          style: TextStyle(
                              color: _isMessageError
                                  ? Colors.red.shade800
                                  : Colors.green.shade800),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isLoading ? null : () => _saveProfile(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 5,
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(localizations.translate('saveChanges'),
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
