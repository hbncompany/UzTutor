import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'package:repetitor_resurs/providers/user_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:repetitor_resurs/models/teaching_center.dart'; // TeachingCenter modelini import qilish
import 'package:repetitor_resurs/providers/app_language_provider.dart'; // app_language_provider'ни импорт қилиш
import 'package:http/http.dart' as http; // HTTP requestlar uchun
import 'dart:convert'; // JSON dekodlash uchun

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _userType = 'client'; // 'client', 'tutor' ёки 'teaching_center'
  bool _isLogin = true;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isLoadingRegions = true; // Вилоятлар юкланмоқда ҳолати

  // Репетитор учун қўшимча маълумотлар
  String _username = '';
  String _phoneNumber = '';
  File? _pickedImage;
  String _imageUrl = ''; // URL ёки placeholder учун
  String _subject = '';
  double _price = 0.0;
  String _description = '';
  String _teachingType = 'online';
  String? _selectedRegion;
  String? _selectedDistrict;
  String _locationTip = '';

  // Ўқув маркази учун қўшимча маълумотлар
  String _centerName = '';
  List<TeachingCenterLocation> _centerLocations = []; // Бир нечта жойлашувлар

  // Ўзбекистон вилоятлари ва туманлари (API'дан юкланади)
  Map<String, List<String>> uzbekistanRegions = {};

  @override
  void initState() {
    super.initState();
    _fetchRegions(); // Вилоятларни API'дан юклаш
  }

  Future<void> _fetchRegions() async {
    setState(() {
      _isLoadingRegions = true;
    });
    try {
      final response = await http.get(Uri.parse(
          'https://hbnnarzullayev.pythonanywhere.com/api/uzb_regions'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        Map<String, List<String>> fetchedRegions = {};
        for (var item in data) {
          final String regionUz = item['name_uz'];
          final String districtUz = item['district_uz'];
          if (!fetchedRegions.containsKey(regionUz)) {
            fetchedRegions[regionUz] = [];
          }
          fetchedRegions[regionUz]!.add(districtUz);
        }
        setState(() {
          uzbekistanRegions = fetchedRegions;
        });
      } else {
        setState(() {
          _errorMessage = 'Вилоятлар юклашда хато: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Вилоятлар юклашда хато: $e';
      });
    } finally {
      setState(() {
        _isLoadingRegions = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImageFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedImageFile != null) {
      setState(() {
        _pickedImage = File(pickedImageFile.path);
        _imageUrl = ''; // Агар расм танланса, URL майдонини тозалаш
      });
    }
  }

  Future<void> _submitAuthForm(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        UserCredential userCredential;
        if (_isLogin) {
          userCredential =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _email,
            password: _password,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.translate('loginSuccess'))),
          );
        } else {
          userCredential =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _email,
            password: _password,
          );

          // Фойдаланувчи профилини Firestore'га сақлаш
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'email': _email,
            'userType': _userType,
            'name': _userType == 'client' || _userType == 'tutor'
                ? _username
                : null,
            'centerName': _userType == 'teaching_center' ? _centerName : null,
            'phoneNumber': _phoneNumber.isNotEmpty ? _phoneNumber : null,
            'imageUrl': _imageUrl.isNotEmpty
                ? _imageUrl
                : (_pickedImage != null
                    ? 'https://placehold.co/150x150/A78BFA/ffffff?text=User' // Placeholder for picked image
                    : null),
            'createdAt': Timestamp.now(),
          });

          // Агар репетитор бўлса, репетитор профилини яратиш
          if (_userType == 'tutor') {
            await FirebaseFirestore.instance
                .collection('tutors')
                .doc(userCredential.user!.uid)
                .set({
              'id': userCredential.user!.uid,
              'name': _username,
              'subject': _subject,
              'rating': 0.0,
              'price': _price,
              'description': _description,
              'imageUrl': _imageUrl.isNotEmpty
                  ? _imageUrl
                  : (_pickedImage != null
                      ? 'https://placehold.co/150x150/A78BFA/ffffff?text=Tutor'
                      : null),
              'reviews': [],
              'teachingType': _teachingType,
              'region': _selectedRegion,
              'district': _selectedDistrict,
              'locationTip': _locationTip.isNotEmpty ? _locationTip : null,
              'createdAt': Timestamp.now(),
              'connectedTeachingCenterIds':
                  [], // Янги: Бошланғичда марказга уланмаган
            });
          }
          // Агар ўқув маркази бўлса, ўқув маркази профилини яратиш
          else if (_userType == 'teaching_center') {
            await FirebaseFirestore.instance
                .collection('teachingCenters')
                .doc(userCredential.user!.uid)
                .set({
              'id': userCredential.user!.uid,
              'name': _centerName,
              'phoneNumber': _phoneNumber.isNotEmpty ? _phoneNumber : null,
              'imageUrl': _imageUrl.isNotEmpty
                  ? _imageUrl
                  : (_pickedImage != null
                      ? 'https://placehold.co/150x150/F87171/ffffff?text=Center' // Placeholder for picked image
                      : null),
              'description': _description,
              'locations': _centerLocations.map((loc) => loc.toMap()).toList(),
              'connectedTutorIds': [], // Бошланғичда уланган репетиторлар йўқ
              'createdAt': Timestamp.now(),
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.translate('registerSuccess'))),
          );
        }
        // UserProvider'ни янгилаш
        Provider.of<UserProvider>(context, listen: false)
            .setUser(userCredential.user);
        Navigator.of(context).pushReplacementNamed('/client_home');
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = _isLogin
              ? localizations.translate('errorLogin',
                  args: {'error': e.message ?? 'Номаълум хато'})
              : localizations.translate('errorRegister',
                  args: {'error': e.message ?? 'Номаълум хато'});
        });
        print(_errorMessage);
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInAsGuest(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInAnonymously();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': 'guest_${userCredential.user!.uid.substring(0, 8)}@anon.com',
        'userType': 'guest',
        'createdAt': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.translate('guestLoginSuccess'))),
      );
      Provider.of<UserProvider>(context, listen: false)
          .setUser(userCredential.user);
      Navigator.of(context).pushReplacementNamed('/client_home');
    } catch (e) {
      setState(() {
        _errorMessage = localizations
            .translate('errorLogin', args: {'error': e.toString()});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final appLanguageProvider = Provider.of<AppLanguageProvider>(
        context); // Provider'дан AppLanguageProvider'ни олиш

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.indigo,
        title: Text(_isLogin
            ? localizations.translate('loginButton')
            : localizations.translate('registerButton')),
        centerTitle: true,
        actions: [
          PopupMenuButton<Locale>(
            onSelected: (Locale locale) {
              appLanguageProvider.changeLanguage(locale); // Тилни ўзгартириш
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
              PopupMenuItem<Locale>(
                value: const Locale('uz'),
                child: Text(localizations.translate('uzbek')),
              ),
              PopupMenuItem<Locale>(
                value: const Locale('ru'),
                child: Text(localizations.translate('russian')),
              ),
              PopupMenuItem<Locale>(
                value: const Locale('en'),
                child: Text(localizations.translate('english')),
              ),
            ],
            icon: const Icon(Icons.language), // Тил белгиси
          ),
        ],
      ),
      body: _isLoadingRegions
          ? Center(child: CircularProgressIndicator()) // Вилоятлар юкланмоқда
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isLogin
                                ? localizations.translate('loginRegisterTitle')
                                : localizations.translate('loginRegisterTitle'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const ValueKey('email'),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: localizations.translate('emailHint'),
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return 'Илтимос, тўғри электрон почта манзилини киритинг.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _email = value!;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('password'),
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText:
                                  localizations.translate('passwordHint'),
                              prefixIcon: const Icon(Icons.lock),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Парол камида 6 белгидан иборат бўлиши керак.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _password = value!;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (!_isLogin) // Фақат рўйхатдан ўтишда фойдаланувчи турини танлаш
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizations.translate('selectUserType'),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(
                                    height: 8), // Dropdown'дан олдинги масофа
                                DropdownButtonFormField<String>(
                                  value: _userType,
                                  decoration: InputDecoration(
                                    labelText: localizations
                                        .translate('selectOption'), // "Танланг"
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    filled: true,
                                    fillColor: Theme.of(context).cardColor,
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'client',
                                      child: Text(localizations
                                          .translate('userTypeClient')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'tutor',
                                      child: Text(localizations
                                          .translate('userTypeTutor')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'teaching_center',
                                      child: Text(localizations
                                          .translate('teachingCenter')),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _userType = value!;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Фойдаланувчи турини танлаш мажбурий.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Репетитор учун қўшимча майдонлар
                                if (_userType == 'tutor')
                                  Column(
                                    children: [
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: localizations
                                              .translate('usernameLabel'),
                                          prefixIcon:
                                              const Icon(Icons.person_outline),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Исм киритиш мажбурий.';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _username = value!;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: localizations
                                              .translate('phoneNumberLabel'),
                                          prefixIcon: const Icon(Icons.phone),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        keyboardType: TextInputType.phone,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Телефон рақами киритиш мажбурий.';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _phoneNumber = value!;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      // Расм танлаш ёки URL киритиш
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              localizations.translate(
                                                  'profileImageSource'),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: _pickImage,
                                                  icon: const Icon(
                                                      Icons.photo_library),
                                                  label: Text(
                                                      localizations.translate(
                                                          'selectImageFromGallery')),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        vertical: 12),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10)),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: TextFormField(
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        localizations.translate(
                                                            'enterImageUrl'),
                                                    border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10)),
                                                  ),
                                                  keyboardType:
                                                      TextInputType.url,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _imageUrl = value;
                                                      _pickedImage =
                                                          null; // URL киритилса, танланган расмни тозалаш
                                                    });
                                                  },
                                                  onSaved: (value) {
                                                    _imageUrl = value ?? '';
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_pickedImage != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 10),
                                              child: Image.file(_pickedImage!,
                                                  height: 100,
                                                  width: 100,
                                                  fit: BoxFit.cover),
                                            ),
                                          if (_pickedImage == null &&
                                              _imageUrl.isEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(
                                                localizations
                                                    .translate('imageRequired'),
                                                style: const TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: localizations
                                              .translate('subjectLabel'),
                                          prefixIcon: const Icon(Icons.book),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Фан киритиш мажбурий.';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _subject = value!;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: localizations
                                              .translate('priceLabel'),
                                          prefixIcon:
                                              const Icon(Icons.attach_money),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
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
                                        onSaved: (value) {
                                          _price = double.parse(value!);
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: localizations
                                              .translate('descriptionLabel'),
                                          prefixIcon:
                                              const Icon(Icons.description),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        maxLines: 3,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Тавсиф киритиш мажбурий.';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _description = value!;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      // Ўқитиш тури
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              localizations.translate(
                                                  'teachingTypeLabel'),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: RadioListTile<String>(
                                                  title: Text(
                                                      localizations.translate(
                                                          'onlineTeaching')),
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
                                                      localizations.translate(
                                                          'offlineTeaching')),
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
                                      // Агар офлайн бўлса, жойлашув маълумотлари
                                      if (_teachingType == 'offline')
                                        Column(
                                          children: [
                                            DropdownButtonFormField<String>(
                                              decoration: InputDecoration(
                                                labelText: localizations
                                                    .translate('selectRegion'),
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                              ),
                                              value: _selectedRegion,
                                              hint: Text(localizations
                                                  .translate('selectRegion')),
                                              items: uzbekistanRegions.keys
                                                  .map((String region) {
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
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Вилоятни танлаш мажбурий.';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 12),
                                            DropdownButtonFormField<String>(
                                              decoration: InputDecoration(
                                                labelText:
                                                    localizations.translate(
                                                        'selectDistrict'),
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                              ),
                                              value: _selectedDistrict,
                                              hint: Text(localizations
                                                  .translate('selectDistrict')),
                                              items: _selectedRegion != null &&
                                                      uzbekistanRegions
                                                          .containsKey(
                                                              _selectedRegion!)
                                                  ? uzbekistanRegions[
                                                          _selectedRegion!]!
                                                      .map((String district) {
                                                      return DropdownMenuItem<
                                                          String>(
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
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Туманни танлаш мажбурий.';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 12),
                                            TextFormField(
                                              decoration: InputDecoration(
                                                labelText:
                                                    localizations.translate(
                                                        'locationTipLabel'),
                                                prefixIcon: const Icon(
                                                    Icons.location_on),
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                              ),
                                              onSaved: (value) {
                                                _locationTip = value ?? '';
                                              },
                                            ),
                                          ],
                                        ),
                                    ],
                                  )
                                // Ўқув маркази учун қўшимча майдонлар
                                else if (_userType == 'teaching_center')
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: localizations
                                              .translate('centerNameLabel'),
                                          prefixIcon: const Icon(Icons.school),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Марказ номи киритиш мажбурий.';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _centerName = value!;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: localizations
                                              .translate('phoneNumberLabel'),
                                          prefixIcon: const Icon(Icons.phone),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        keyboardType: TextInputType.phone,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Телефон рақами киритиш мажбурий.';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _phoneNumber = value!;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      // Расм танлаш ёки URL киритиш
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              localizations.translate(
                                                  'profileImageSource'),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: _pickImage,
                                                  icon: const Icon(
                                                      Icons.photo_library),
                                                  label: Text(
                                                      localizations.translate(
                                                          'selectImageFromGallery')),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        vertical: 12),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10)),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: TextFormField(
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        localizations.translate(
                                                            'enterImageUrl'),
                                                    border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10)),
                                                  ),
                                                  keyboardType:
                                                      TextInputType.url,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _imageUrl = value;
                                                      _pickedImage = null;
                                                    });
                                                  },
                                                  onSaved: (value) {
                                                    _imageUrl = value ?? '';
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_pickedImage != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 10),
                                              child: Image.file(_pickedImage!,
                                                  height: 100,
                                                  width: 100,
                                                  fit: BoxFit.cover),
                                            ),
                                          if (_pickedImage == null &&
                                              _imageUrl.isEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(
                                                localizations
                                                    .translate('imageRequired'),
                                                style: const TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: localizations
                                              .translate('descriptionLabel'),
                                          prefixIcon:
                                              const Icon(Icons.description),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        maxLines: 3,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Тавсиф киритиш мажбурий.';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _description = value!;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                          localizations
                                              .translate('locationsLabel'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(height: 8),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: _centerLocations.length,
                                        itemBuilder: (context, index) {
                                          final loc = _centerLocations[index];
                                          return Card(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: ListTile(
                                              title: Text(
                                                  '${loc.region}, ${loc.district}'),
                                              subtitle:
                                                  Text(loc.locationTip ?? ''),
                                              trailing: IconButton(
                                                icon: const Icon(
                                                    Icons.remove_circle,
                                                    color: Colors.red),
                                                onPressed: () {
                                                  setState(() {
                                                    _centerLocations
                                                        .removeAt(index);
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
                                              await _showAddLocationDialog(
                                                  context);
                                          if (newLocation != null) {
                                            setState(() {
                                              _centerLocations.add(newLocation);
                                            });
                                          }
                                        },
                                        icon: const Icon(Icons.add_location),
                                        label: Text(localizations
                                            .translate('addLocation')),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Харитадан жой танлаш учун placeholder
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Харитадан жой танлаш функцияси тез орада қўшилади!')),
                                          );
                                        },
                                        icon: const Icon(Icons.map),
                                        label: Text(
                                            'Харитадан жой танлаш (Тез орада)'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          backgroundColor: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 20),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _submitAuthForm(context),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      _isLogin
                                          ? localizations
                                              .translate('loginButton')
                                          : localizations
                                              .translate('registerButton'),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _errorMessage = null; // Хато хабарини тозалаш
                              });
                            },
                            child: Text(
                              _isLogin
                                  ? localizations.translate('registerButton')
                                  : localizations.translate('loginButton'),
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor),
                            ),
                          ),
                          const Divider(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _signInAsGuest(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(
                                    color: Theme.of(context).primaryColor),
                                foregroundColor: Theme.of(context).primaryColor,
                              ),
                              child: Text(
                                localizations.translate('continueAsGuest'),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
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
                        items: tempRegion != null &&
                                uzbekistanRegions.containsKey(tempRegion!)
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
}
