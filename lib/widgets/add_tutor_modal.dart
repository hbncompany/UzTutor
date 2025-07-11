import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';

class AddTutorModal extends StatefulWidget {
  const AddTutorModal({super.key});

  @override
  State<AddTutorModal> createState() => _AddTutorModalState();
}

class _AddTutorModalState extends State<AddTutorModal> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _subject = '';
  double _rating = 5.0;
  double _price = 0.0;
  String _description = '';
  String _imageUrl = '';
  String? _message;
  bool _isLoading = false;

  Future<void> _addTutor(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
        _message = null;
      });

      try {
        await FirebaseFirestore.instance.collection('tutors').add({
          'name': _name,
          'subject': _subject,
          'rating': _rating,
          'price': _price,
          'description': _description,
          'imageUrl': _imageUrl.isEmpty ? null : _imageUrl,
          'reviews': [], // Бошланғич шарҳлар
          'createdAt': Timestamp.now(),
        });
        setState(() {
          _message = localizations.translate('tutorAddedSuccess');
        });
        // Формани тозалаш
        _formKey.currentState!.reset();
        _rating = 5.0;
        _price = 0.0;
        _imageUrl = '';

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop(); // Модални ёпиш
        });
      } catch (e) {
        setState(() {
          _message = localizations
              .translate('tutorAddError', args: {'error': e.toString()});
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('addTutor'),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: InputDecoration(
                labelText: localizations.translate('nameLabel'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Исм киритиш мажбурий.';
                }
                return null;
              },
              onSaved: (value) {
                _name = value!;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                labelText: localizations.translate('subjectLabel'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                labelText: localizations.translate('priceLabel'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    double.tryParse(value) == null) {
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
                labelText: localizations.translate('descriptionLabel'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
            TextFormField(
              decoration: InputDecoration(
                labelText: localizations.translate('imageUrlLabel'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.url,
              onSaved: (value) {
                _imageUrl = value ?? '';
              },
            ),
            const SizedBox(height: 20),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _message!,
                  style: TextStyle(
                      color: _message!.contains('хато')
                          ? Colors.red
                          : Colors.green),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _addTutor(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(localizations.translate('add'),
                        style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
