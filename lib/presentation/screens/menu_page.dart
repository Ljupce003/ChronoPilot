import 'package:chrono_pilot/presentation/widgets/home_button.dart';
import 'package:chrono_pilot/repository/auth_provider.dart';
import 'package:chrono_pilot/repository/event_provider.dart';
import 'package:chrono_pilot/service/holiday_api_service.dart';
import 'package:chrono_pilot/service/holiday_import_service.dart';
import 'package:chrono_pilot/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ChronoPilot"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _openHolidayImportDialog(context),
            tooltip: 'Import Holidays',
            icon: const Icon(Icons.public),
          ),
          IconButton(
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
            tooltip: 'Toggle Theme',
            icon: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                );
              },
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO later: navigate to profile
              Navigator.pushNamed(context, "/profile");
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            HomeButton(
              title: "Calendar View",
              icon: Icons.calendar_month,
              onTap: () => Navigator.pushNamed(context, "/calendar"),
            ),

            const SizedBox(height: 16),

            HomeButton(
              title: "Event List",
              icon: Icons.list,
              onTap: () => Navigator.pushNamed(context, "/events"),
            ),

            const SizedBox(height: 16),

            HomeButton(
              title: "Create Event",
              icon: Icons.add,
              onTap: () => Navigator.pushNamed(context, "/create-event"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openHolidayImportDialog(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to import holidays.')),
      );
      return;
    }

    final eventProvider = context.read<EventProvider>();
    final api = HolidayApiService();
    final importService = HolidayImportService(api: api, eventProvider: eventProvider);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return _HolidayImportDialog(
          importService: importService,
          userId: userId,
        );
      },
    );
  }
}

class _HolidayImportDialog extends StatefulWidget {
  final HolidayImportService importService;
  final String userId;

  const _HolidayImportDialog({
    required this.importService,
    required this.userId,
  });

  @override
  State<_HolidayImportDialog> createState() => _HolidayImportDialogState();
}

class _HolidayImportDialogState extends State<_HolidayImportDialog> {
  final _yearController = TextEditingController(text: DateTime.now().year.toString());
  Future<List<Map<String, String>>>? _countriesFuture;
  List<Map<String, String>> _countries = [];
  Map<String, String>? _selectedCountry;
  String? _selectedCountryCode;
  String? _selectedCountryName;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _countriesFuture = _loadCountries();
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  Future<List<Map<String, String>>> _loadCountries() async {
    final countries = await HolidayApiService().getAvailableCountries();
    final mapped = countries
        .map((country) => {
              'code': country.countryCode,
              'name': country.name,
              'label': country.displayLabel,
            })
        .toList();
    _countries = mapped;
    return mapped;
  }

  Future<void> _import() async {
    final year = int.tryParse(_yearController.text.trim());
    if (year == null || year < 1900 || year > 2100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid year.')),
      );
      return;
    }
    final code = _selectedCountryCode;
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a country.')),
      );
      return;
    }

    setState(() => _isImporting = true);
    try {
      final imported = await widget.importService.importHolidays(
        userId: widget.userId,
        year: year,
        countryCode: code,
        countryName: _selectedCountryName,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $imported holidays.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import holidays: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Holidays'),
      content: FutureBuilder<List<Map<String, String>>>(
        future: _countriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Text('Failed to load countries: ${snapshot.error}');
          }

          final countries = snapshot.data ?? const [];
          if (countries.isEmpty) {
            return const Text('No countries available.');
          }

          _countries = countries;
          _selectedCountry ??= countries.first;
          _selectedCountryCode ??= _selectedCountry?['code'];
          _selectedCountryName ??= _selectedCountry?['name'];

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Autocomplete<Map<String, String>>(
                  displayStringForOption: (option) => option['label'] ?? option['code'] ?? '',
                  initialValue: TextEditingValue(
                    text: _selectedCountry?['label'] ?? _selectedCountry?['code'] ?? '',
                  ),
                  optionsBuilder: (TextEditingValue value) {
                    final query = value.text.trim().toLowerCase();
                    if (query.isEmpty) {
                      return countries;
                    }
                    return countries.where((country) {
                      final label = (country['label'] ?? '').toLowerCase();
                      final code = (country['code'] ?? '').toLowerCase();
                      return label.contains(query) || code.contains(query);
                    });
                  },
                  onSelected: (value) {
                    setState(() {
                      _selectedCountry = value;
                      _selectedCountryCode = value['code'];
                      _selectedCountryName = value['name'];
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    if ((_selectedCountry?['label'] ?? '').isNotEmpty && controller.text.isEmpty) {
                      controller.text = _selectedCountry?['label'] ?? '';
                    }

                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        hintText: 'Type to search a country',
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 240, maxWidth: 320),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(
                                  option['label'] ?? option['code'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(option['code'] ?? ''),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Year'),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isImporting ? null : _import,
          child: _isImporting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Import'),
        ),
      ],
    );
  }
}