import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class BannerFormScreen extends StatefulWidget {
  const BannerFormScreen({super.key});

  @override
  State<BannerFormScreen> createState() => _BannerFormScreenState();
}

class _BannerFormScreenState extends State<BannerFormScreen> {
  final _titleController = TextEditingController();
  final _redirectUrlController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isActive = true;
  DateTime? _startDate;
  DateTime? _endDate;
  File? _selectedImage;
  Uint8List? _selectedImageBytes; // Web-friendly

  final picker = ImagePicker();
  final supabase = Supabase.instance.client;

  final dateFormat = DateFormat('yyyy-MM-dd');

  // Pagination
  final int _limit = 5;
  int _page = 0;
  int _totalBanners = 0;
  List<Map<String, dynamic>> _banners = [];

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final result = await picker.pickImage(source: ImageSource.gallery);
      if (result != null) {
        final bytes = await result.readAsBytes();
        setState(() => _selectedImageBytes = bytes);
      }
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _selectedImageBytes = bytes);
      }
    }
  }

  Future<void> _saveBanner() async {
    if ((_selectedImage == null && _selectedImageBytes == null) ||
        _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and select image.')),
      );
      return;
    }

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';

      if (_selectedImageBytes != null) {
        await supabase.storage.from('banners').uploadBinary(fileName, _selectedImageBytes!);
      } else if (_selectedImage != null) {
        await supabase.storage.from('banners').upload(fileName, _selectedImage!);
      }

      final imageUrl = supabase.storage.from('banners').getPublicUrl(fileName);

      await supabase.from('banners').insert({
        'title': _titleController.text,
        'subtitle': _locationController.text,
        'image_url': imageUrl,
        'redirect_url': _redirectUrlController.text.isEmpty
            ? null
            : _redirectUrlController.text,
        'is_active': _isActive,
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner saved successfully!')),
      );

      _titleController.clear();
      _redirectUrlController.clear();
      _locationController.clear();
      setState(() {
        _selectedImage = null;
        _selectedImageBytes = null;
        _isActive = true;
        _startDate = null;
        _endDate = null;
      });

      _loadBanners();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving banner: $e')),
      );
    }
  }

 Future<void> _loadBanners() async {
  try {
    // 1️⃣ Fetch paginated banners
    final pageResponse = await supabase
        .from('banners')
        .select('*')
        .range(_page * _limit, (_page + 1) * _limit - 1)
        .order('created_at', ascending: false);

    if (pageResponse is List) {
      setState(() => _banners = List<Map<String, dynamic>>.from(pageResponse));
    } else {
      setState(() => _banners = []);
    }

    // 2️⃣ Fetch total count (simple and compatible)
    final countResponse = await supabase.from('banners').select('id');
    if (countResponse is List) {
      setState(() => _totalBanners = countResponse.length);
    } else {
      setState(() => _totalBanners = 0);
    }
  } catch (e, st) {
    debugPrint('Error loading banners: $e\n$st');
  }
}



  void _previousPage() {
    if (_page > 0) {
      setState(() {
        _page--;
      });
      _loadBanners();
    }
  }

  void _nextPage() {
    if ((_page + 1) * _limit < _totalBanners) {
      setState(() {
        _page++;
      });
      _loadBanners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add / Update Banner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // === Form ===
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Banner Title'),
            ),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Banner Location'),
            ),
            TextField(
              controller: _redirectUrlController,
              decoration: const InputDecoration(labelText: 'Redirect URL'),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Is Active'),
              value: _isActive,
              onChanged: (val) => setState(() => _isActive = val),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                    child: Text(_startDate == null
                        ? 'Select Start Date'
                        : 'Start: ${dateFormat.format(_startDate!)}'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _endDate = picked);
                    },
                    child: Text(_endDate == null
                        ? 'Select End Date'
                        : 'End: ${dateFormat.format(_endDate!)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: _selectedImageBytes == null
                  ? Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Icon(Icons.add_a_photo, size: 40),
                    )
                  : Image.memory(_selectedImageBytes!, height: 180, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveBanner,
              icon: const Icon(Icons.save),
              label: const Text('Save Banner'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 30),

            // === Banner Table ===
           Text('Banners', style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                 
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Location')),
                  DataColumn(label: Text('Active')),
                  DataColumn(label: Text('Start Date')),
                  DataColumn(label: Text('End Date')),
                ],
                rows: _banners
                    .map(
                      (banner) => DataRow(
                        cells: [
                         
                          DataCell(Text(banner['title'] ?? '')),
                          DataCell(Text(banner['subtitle'] ?? '')),
                          DataCell(Text((banner['is_active'] ?? false).toString())),
                          DataCell(Text(banner['start_date'] != null
                              ? dateFormat.format(DateTime.parse(banner['start_date']))
                              : '')),
                          DataCell(Text(banner['end_date'] != null
                              ? dateFormat.format(DateTime.parse(banner['end_date']))
                              : '')),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),

            // Pagination Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _previousPage,
                  child: const Text('Previous'),
                ),
                Text('Page ${_page + 1}'),
                TextButton(
                  onPressed: _nextPage,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
