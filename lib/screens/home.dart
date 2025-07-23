import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:real_estate/models/propert_services.dart';
import 'package:real_estate/models/property_card.dart';
import 'package:real_estate/screens/property_page.dart';
import 'package:real_estate/widgets/bottom_nav.dart';
import 'package:real_estate/models/property.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Property> properties = [];
  List<Property> filteredProperties = [];
  List<Property> userProperties = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedType;
  String? selectedLocation;
  String sortBy = 'title_asc';
  String currentLocation = 'Fetching location...';
  bool isLocationLoading = true;
  String? selectedManualLocation;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _getCurrentLocation();
    _loadUserListings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/house.png'), context);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Location service check timed out');
        },
      );

      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            currentLocation = 'Enable GPS in settings';
            isLocationLoading = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              currentLocation = 'Grant location permission';
              isLocationLoading = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            currentLocation = 'Allow location in app settings';
            isLocationLoading = false;
          });
        }
        return;
      }

      Position position =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Location request timed out');
            },
          );

      List<Placemark> placemarks =
          await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Geocoding request timed out');
            },
          );

      if (placemarks.isEmpty) {
        throw Exception('No address found for coordinates');
      }

      Placemark place = placemarks.first;
      String address = [
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.country,
      ].where((e) => e != null && e.isNotEmpty).join(', ');

      if (mounted) {
        setState(() {
          currentLocation = address.isNotEmpty ? address : 'Unknown location';
          isLocationLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          currentLocation = 'Failed to get location. Tap to retry.';
          isLocationLoading = false;
        });
      }
    }
  }

  Future<void> _loadProperties() async {
    try {
      final loadedProperties = await PropertyService.loadMockProperties();
      final prefs = await SharedPreferences.getInstance();
      final boughtList = prefs.getStringList('bought_properties') ?? [];
      final paidList = prefs.getStringList('paid_properties') ?? [];
      final boughtIds = <String>{};
      for (final item in boughtList) {
        try {
          final map = jsonDecode(item) as Map<String, dynamic>;
          if (map['id'] != null) boughtIds.add(map['id'].toString());
        } catch (_) {}
      }
      for (final id in paidList) {
        boughtIds.add(id);
      }
      final filtered = loadedProperties
          .where((p) => !boughtIds.contains(p.id))
          .toList();
      if (mounted) {
        setState(() {
          properties = filtered;
          filteredProperties = _applyFiltersAndSort(filtered);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Failed to load properties: $e')),
        );
      }
    }
  }

  Future<void> _loadUserListings() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('user_listings') ?? [];
    setState(() {
      userProperties = list.map((e) {
        final map = jsonDecode(e) as Map<String, dynamic>;
        // Ensure all fields are present for Property
        return Property(
          id: map['id'] ?? '',
          title: map['title'] ?? '',
          price: map['price'] ?? '',
          location: map['location'] ?? '',
          description: map['description'] ?? '',
          bedrooms: map['bedrooms'] ?? '',
          bathrooms: map['bathrooms'] ?? '',
          area: map['area'] ?? '',
          type: map['type'] ?? '',
          url: map['url'] ?? '',
          scrapedAt: map['scraped_at'] ?? '',
          images: (map['images'] is List)
              ? List<String>.from(map['images'])
              : (map['imagePath'] != null ? [map['imagePath']] : []),
        );
      }).toList();
    });
  }

  List<Property> _applyFiltersAndSort(List<Property> props) {
    var result = props.where((property) {
      final matchesSearch =
          searchQuery.isEmpty ||
          property.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          property.location.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesType = selectedType == null || property.type == selectedType;
      final matchesLocation =
          selectedLocation == null || property.location == selectedLocation;
      return matchesSearch && matchesType && matchesLocation;
    }).toList();

    switch (sortBy) {
      case 'title_asc':
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'title_desc':
        result.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'price_asc':
        result.sort((a, b) {
          if (a.price == 'Offers are invited') return 1;
          if (b.price == 'Offers are invited') return -1;
          final aPrice =
              double.tryParse(a.price.replaceAll(RegExp(r'[^\d]'), '')) ??
              double.infinity;
          final bPrice =
              double.tryParse(b.price.replaceAll(RegExp(r'[^\d]'), '')) ??
              double.infinity;
          return aPrice.compareTo(bPrice);
        });
        break;
      case 'price_desc':
        result.sort((a, b) {
          if (a.price == 'Offers are invited') return 1;
          if (b.price == 'Offers are invited') return -1;
          final aPrice =
              double.tryParse(a.price.replaceAll(RegExp(r'[^\d]'), '')) ??
              double.infinity;
          final bPrice =
              double.tryParse(b.price.replaceAll(RegExp(r'[^\d]'), '')) ??
              double.infinity;
          return bPrice.compareTo(aPrice);
        });
        break;
    }
    return result;
  }

  void _updateSearchQuery(String query) {
    if (mounted) {
      setState(() {
        searchQuery = query;
        filteredProperties = _applyFiltersAndSort(properties);
      });
    }
  }

  void _showFilterSortDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? tempType = selectedType;
        String? tempLocation = selectedLocation;
        String tempSortBy = sortBy;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final types = properties.map((p) => p.type).toSet().toList();
            final locations = properties
                .map((p) => p.location)
                .toSet()
                .toList();
            return AlertDialog(
              title: const Text('Filter & Sort'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Property Type',
                      ),
                      value: tempType,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Types'),
                        ),
                        ...types.map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => tempType = value),
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Location'),
                      value: tempLocation,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Locations'),
                        ),
                        ...locations.map(
                          (loc) =>
                              DropdownMenuItem(value: loc, child: Text(loc)),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => tempLocation = value),
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Sort By'),
                      value: tempSortBy,
                      items: const [
                        DropdownMenuItem(
                          value: 'title_asc',
                          child: Text('Title A-Z'),
                        ),
                        DropdownMenuItem(
                          value: 'title_desc',
                          child: Text('Title Z-A'),
                        ),
                        DropdownMenuItem(
                          value: 'price_asc',
                          child: Text('Price Low-High'),
                        ),
                        DropdownMenuItem(
                          value: 'price_desc',
                          child: Text('Price High-Low'),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => tempSortBy = value!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        selectedType = null;
                        selectedLocation = null;
                        sortBy = 'title_asc';
                        filteredProperties = _applyFiltersAndSort(properties);
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        selectedType = tempType;
                        selectedLocation = tempLocation;
                        sortBy = tempSortBy;
                        filteredProperties = _applyFiltersAndSort(properties);
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLocationPicker() {
    showDialog(
      context: context,
      builder: (context) {
        String? tempLocation = selectedManualLocation;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final locations = properties
                .map((p) => p.location)
                .toSet()
                .toList();
            return AlertDialog(
              title: const Text('Select Location'),
              content: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Location'),
                value: tempLocation,
                items: locations
                    .map(
                      (loc) => DropdownMenuItem(value: loc, child: Text(loc)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => tempLocation = value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        selectedManualLocation = tempLocation;
                        currentLocation = tempLocation ?? currentLocation;
                        isLocationLoading = false;
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: true,
      child: Stack(
        children: [
          Scaffold(
            key: _scaffoldMessengerKey,
            backgroundColor: theme.primaryColor,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.primaryColor,
                            border: Border.all(color: Colors.white),
                          ),
                          child: const Icon(
                            Icons.home_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (currentLocation.contains('Failed') ||
                                currentLocation.contains('Enable') ||
                                currentLocation.contains('Grant') ||
                                currentLocation.contains('Allow')) {
                              if (mounted) {
                                setState(() {
                                  isLocationLoading = true;
                                  currentLocation = 'Fetching location...';
                                });
                              }
                              _getCurrentLocation();
                            } else {
                              _showLocationPicker();
                            }
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Current location",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withAlpha(179),
                                ),
                              ),
                              Row(
                                children: [
                                  isLocationLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.location_on,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      selectedManualLocation ?? currentLocation,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            Navigator.pushNamed(context, "/message");
                          },
                          icon: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(102),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: theme.cardColor.withAlpha(102),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    onChanged: _updateSearchQuery,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search by title or location...',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withAlpha(179),
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _showFilterSortDialog,
                          icon: const Icon(
                            Icons.filter_list,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(102),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredProperties.isEmpty && userProperties.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.search_off,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    searchQuery.isEmpty
                                        ? 'No properties available'
                                        : 'No results for "$searchQuery"',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadProperties,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                await _loadProperties();
                                await _loadUserListings();
                              },
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  // Poster/banner first
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomLeft,
                                        stops: [0.4, 1],
                                        colors: [
                                          Color(0xff35573b),
                                          Colors.grey,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                Text(
                                                  'GET YOUR 10%\nCASHBACK',
                                                  style: theme
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                ),
                                                Text(
                                                  '*Expires 31 Sept 2025',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.white,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Image.asset(
                                          "assets/house.png",
                                          width: 130,
                                          fit: BoxFit.cover,
                                        ),
                                        const SizedBox(width: 20),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // User listings below poster/banner
                                  if (userProperties.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                        left: 4,
                                      ),
                                      child: Text(
                                        'Your Listings',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    ...userProperties.map(
                                      (property) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12.0,
                                        ),
                                        child: PropertyCard(
                                          property: property,
                                          onTap: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PropertyPage(
                                                      property: property,
                                                    ),
                                              ),
                                            );
                                            if (result == true) {
                                              await _loadProperties();
                                              await _loadUserListings();
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Recommended for you',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      TextButton(
                                        onPressed: _showFilterSortDialog,
                                        child: Row(
                                          children: [
                                            Text(
                                              'Filter & Sort',
                                              style: theme.textTheme.titleSmall,
                                            ),
                                            const Icon(
                                              Icons.keyboard_arrow_down,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ...filteredProperties.map(
                                    (property) => Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: PropertyCard(
                                        property: property,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PropertyPage(
                                                    property: property,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 80,
            right: 80,
            child: HomeBottomNavBar(
              onProfileReturn: () async {
                await _loadUserListings();
                await _loadProperties();
              },
            ),
          ),
        ],
      ),
    );
  }
}
