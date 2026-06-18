import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/countries_vm.dart';
import '../../components/country_card.dart';
import 'country_details_screen.dart';

class CountriesScreen extends StatefulWidget {
  const CountriesScreen({super.key});

  @override
  State<CountriesScreen> createState() => _CountriesScreenState();
}

class _CountriesScreenState extends State<CountriesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final countriesVm = context.read<CountriesViewModel>();
      if (countriesVm.allCountries.isEmpty && !countriesVm.isLoading) {
        countriesVm.loadCountries();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Countries')),
      body: Consumer<CountriesViewModel>(
        builder: (context, countriesVm, _) {
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search countries...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                countriesVm.setSearchQuery('');
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    countriesVm.setSearchQuery(value);
                  },
                ),
              ),

              // Error message
              if (countriesVm.errorMessage != null && !countriesVm.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              countriesVm.errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Content
              Expanded(
                child:
                    countriesVm.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : countriesVm.filteredCountries.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.flag_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text('No countries found'),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  countriesVm.loadCountries();
                                },
                                child: const Text('Reload'),
                              ),
                            ],
                          ),
                        )
                        : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                          itemCount: countriesVm.filteredCountries.length,
                          itemBuilder: (context, index) {
                            final country =
                                countriesVm.filteredCountries[index];
                            return CountryCard(
                              country: country,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => CountryDetailsScreen(
                                          country: country,
                                        ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}
