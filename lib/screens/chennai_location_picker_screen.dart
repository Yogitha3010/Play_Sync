import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_theme.dart';

class ChennaiLocationSelection {
  final String label;
  final LatLng coordinates;

  const ChennaiLocationSelection({
    required this.label,
    required this.coordinates,
  });
}

class ChennaiLocationPickerScreen extends StatefulWidget {
  final String? initialLabel;

  const ChennaiLocationPickerScreen({
    super.key,
    this.initialLabel,
  });

  @override
  State<ChennaiLocationPickerScreen> createState() =>
      _ChennaiLocationPickerScreenState();
}

class _ChennaiLocationPickerScreenState
    extends State<ChennaiLocationPickerScreen> {
  static const LatLng _chennaiCenter = LatLng(13.0827, 80.2707);
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: _chennaiCenter,
    zoom: 11.7,
  );

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Marker? _selectedMarker;
  String? _selectedLabel;
  bool _isResolvingLocation = false;
  bool _isSearching = false;

  final List<_SuggestedChennaiSpot> _suggestedSpots = const [
    _SuggestedChennaiSpot('Adyar', 'Adyar, Chennai', LatLng(13.0067, 80.2574)),
    _SuggestedChennaiSpot('Anna Nagar', 'Anna Nagar, Chennai', LatLng(13.0849, 80.2101)),
    _SuggestedChennaiSpot('Velachery', 'Velachery, Chennai', LatLng(12.9759, 80.2212)),
    _SuggestedChennaiSpot('OMR', 'OMR, Chennai', LatLng(12.9121, 80.2295)),
    _SuggestedChennaiSpot('T Nagar', 'T Nagar, Chennai', LatLng(13.0418, 80.2341)),
    _SuggestedChennaiSpot('Porur', 'Porur, Chennai', LatLng(13.0352, 80.1588)),
    _SuggestedChennaiSpot('Tambaram', 'Tambaram, Chennai', LatLng(12.9249, 80.1000)),
    _SuggestedChennaiSpot('Sholinganallur', 'Sholinganallur, Chennai', LatLng(12.9010, 80.2279)),
    _SuggestedChennaiSpot('Guindy', 'Guindy, Chennai', LatLng(13.0105, 80.2206)),
    _SuggestedChennaiSpot('Nungambakkam', 'Nungambakkam, Chennai', LatLng(13.0604, 80.2496)),
  ];

  List<_SuggestedChennaiSpot> get _searchSuggestions {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _suggestedSpots.take(6).toList();
    }

    final startsWith = _suggestedSpots
        .where(
          (spot) =>
              spot.name.toLowerCase().startsWith(query) ||
              spot.label.toLowerCase().startsWith(query),
        )
        .toList();
    final contains = _suggestedSpots
        .where(
          (spot) =>
              !startsWith.contains(spot) &&
              (spot.name.toLowerCase().contains(query) ||
                  spot.label.toLowerCase().contains(query)),
        )
        .toList();

    return [...startsWith, ...contains].take(6).toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedLabel = widget.initialLabel;
    _searchController.text = widget.initialLabel ?? '';
    _searchController.addListener(_handleSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _searchLocation() async {
    final rawQuery = _searchController.text.trim();
    if (rawQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type a Chennai area to search.')),
      );
      return;
    }

    final exactSuggestion = _suggestedSpots.cast<_SuggestedChennaiSpot?>().firstWhere(
          (spot) =>
              spot!.name.toLowerCase() == rawQuery.toLowerCase() ||
              spot.label.toLowerCase() == rawQuery.toLowerCase(),
          orElse: () => null,
        );
    if (exactSuggestion != null) {
      await _selectSuggestedSpot(exactSuggestion);
      return;
    }

    final softSuggestion = _searchSuggestions.isNotEmpty ? _searchSuggestions.first : null;
    if (softSuggestion != null && rawQuery.length <= 3) {
      await _selectSuggestedSpot(softSuggestion);
      return;
    }

    final query = rawQuery.toLowerCase().contains('chennai')
        ? rawQuery
        : '$rawQuery, Chennai';

    setState(() {
      _isSearching = true;
    });

    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) {
        throw Exception('No matching location found.');
      }

      final coordinates = LatLng(
        locations.first.latitude,
        locations.first.longitude,
      );

      if (!_isInsideChennai(coordinates)) {
        throw Exception('Search only supports locations inside Chennai.');
      }

      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: coordinates, zoom: 14.6),
        ),
      );

      await _setSelectedLocation(coordinates, fallbackLabel: rawQuery);
      _searchFocusNode.unfocus();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location search failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectSuggestedSpot(_SuggestedChennaiSpot spot) async {
    _searchController.text = spot.name;
    _searchFocusNode.unfocus();
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: spot.coordinates, zoom: 14.8),
      ),
    );
    await _setSelectedLocation(spot.coordinates, fallbackLabel: spot.label);
  }

  Future<void> _handleMapTap(LatLng coordinates) async {
    if (!_isInsideChennai(coordinates)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a location inside Chennai.'),
        ),
      );
      return;
    }

    _searchFocusNode.unfocus();
    await _setSelectedLocation(coordinates);
  }

  Future<void> _handleMarkerDragged(LatLng coordinates) async {
    if (!_isInsideChennai(coordinates)) {
      return;
    }
    await _setSelectedLocation(coordinates);
  }

  Future<void> _setSelectedLocation(
    LatLng coordinates, {
    String? fallbackLabel,
  }) async {
    setState(() {
      _isResolvingLocation = true;
      _selectedMarker = Marker(
        markerId: const MarkerId('selected_chennai_location'),
        position: coordinates,
        draggable: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: fallbackLabel ?? 'Selected location',
          snippet: 'Drag the pin to fine tune',
        ),
        onDragEnd: _handleMarkerDragged,
      );
      _selectedLabel = fallbackLabel ?? 'Selected Chennai location';
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );
      final label = _buildLabel(
        placemarks.isNotEmpty ? placemarks.first : null,
        coordinates,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedLabel = label;
        _searchController.text = label;
        _selectedMarker = _selectedMarker?.copyWith(
          infoWindowParam: InfoWindow(
            title: label,
            snippet: 'Drag the pin to fine tune',
          ),
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      final fallback = fallbackLabel ?? 'Pinned location in Chennai';
      setState(() {
        _selectedLabel = fallback;
        _searchController.text = fallback;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
        });
      }
    }
  }

  String _buildLabel(Placemark? placemark, LatLng coordinates) {
    final segments = <String>[];

    void addSegment(String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        return;
      }
      if (!segments.contains(trimmed)) {
        segments.add(trimmed);
      }
    }

    addSegment(placemark?.subLocality);
    addSegment(placemark?.locality);
    addSegment(placemark?.subAdministrativeArea);

    if (!segments.any((segment) => segment.toLowerCase().contains('chennai'))) {
      segments.add('Chennai');
    }

    if (segments.length > 2) {
      return segments.take(2).join(', ');
    }

    if (segments.isNotEmpty) {
      return segments.join(', ');
    }

    return 'Chennai (${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)})';
  }

  bool _isInsideChennai(LatLng coordinates) {
    return coordinates.latitude >= 12.82 &&
        coordinates.latitude <= 13.24 &&
        coordinates.longitude >= 80.08 &&
        coordinates.longitude <= 80.34;
  }

  void _confirmSelection() {
    final marker = _selectedMarker;
    final label = _selectedLabel;
    if (marker == null || label == null || label.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search or tap on the map to choose a Chennai location.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      ChennaiLocationSelection(label: label, coordinates: marker.position),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _searchSuggestions;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Choose Chennai Location'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.surfaceCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search by typing or tap directly on the map.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchLocation(),
                          decoration: InputDecoration(
                            hintText: 'Search Chennai area',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isSearching ? null : _searchLocation,
                        child: _isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final spot = suggestions[index];
                        return ActionChip(
                          avatar: const Icon(Icons.place_outlined, size: 18),
                          label: Text(spot.name),
                          onPressed: () => _selectSuggestedSpot(spot),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: _initialCameraPosition,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      compassEnabled: true,
                      mapToolbarEnabled: false,
                      onMapCreated: (controller) {
                        if (!_mapController.isCompleted) {
                          _mapController.complete(controller);
                        }
                      },
                      onTap: _handleMapTap,
                      markers: _selectedMarker == null
                          ? const <Marker>{}
                          : <Marker>{_selectedMarker!},
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.touch_app_rounded,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Tap anywhere on the map or drag the blue pin to fine tune your location.',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isResolvingLocation || _isSearching)
                      const Positioned(
                        top: 90,
                        left: 16,
                        right: 16,
                        child: LinearProgressIndicator(minHeight: 4),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.surfaceCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Location',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedLabel ?? 'No location selected yet',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  if (_selectedMarker != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${_selectedMarker!.position.latitude.toStringAsFixed(4)}, ${_selectedMarker!.position.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(color: AppTheme.mutedText),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_isResolvingLocation || _isSearching)
                          ? null
                          : _confirmSelection,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Use This Location'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedChennaiSpot {
  final String name;
  final String label;
  final LatLng coordinates;

  const _SuggestedChennaiSpot(this.name, this.label, this.coordinates);
}
