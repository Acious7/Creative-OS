import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../domain/osm_location_service.dart';

class OsmMapView extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final int initialZoom;
  final bool isInteractive;
  final double height;
  final ValueChanged<OsmCoordinates>? onCoordinatesChanged;
  final VoidCallback? onUseMyLocation;

  const OsmMapView({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    this.initialZoom = 15,
    this.isInteractive = true,
    this.height = 240,
    this.onCoordinatesChanged,
    this.onUseMyLocation,
  });

  @override
  State<OsmMapView> createState() => _OsmMapViewState();
}

class OsmCoordinates {
  final double latitude;
  final double longitude;

  const OsmCoordinates(this.latitude, this.longitude);

  @override
  String toString() =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

class _OsmMapViewState extends State<OsmMapView> {
  late double _centerLat;
  late double _centerLon;
  late int _zoom;
  bool _isDragging = false;
  double _panDeltaX = 0;
  double _panDeltaY = 0;

  @override
  void initState() {
    super.initState();
    _centerLat = widget.initialLatitude;
    _centerLon = widget.initialLongitude;
    _zoom = widget.initialZoom.clamp(11, 18);
  }

  @override
  void didUpdateWidget(covariant OsmMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.initialLatitude != widget.initialLatitude ||
            oldWidget.initialLongitude != widget.initialLongitude) &&
        !_isDragging) {
      setState(() {
        _centerLat = widget.initialLatitude;
        _centerLon = widget.initialLongitude;
      });
    }
  }

  void _zoomIn() {
    if (_zoom < 18) {
      EtoleHaptics.selection();
      setState(() => _zoom++);
    }
  }

  void _zoomOut() {
    if (_zoom > 11) {
      EtoleHaptics.selection();
      setState(() => _zoom--);
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isInteractive) return;
    setState(() {
      _isDragging = true;
      _panDeltaX = 0;
      _panDeltaY = 0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isInteractive) return;

    // Convert pixel delta into lat/lon displacement at current zoom
    final n = 1 << _zoom;
    final dLon = -details.delta.dx / (256.0 * n) * 360.0;

    // Mercator Y conversion
    final currentLatRad = _centerLat * pi / 180.0;
    final currentY =
        (1.0 - log(tan(currentLatRad) + 1.0 / cos(currentLatRad)) / pi) /
        2.0 *
        n;
    final newY = currentY - (details.delta.dy / 256.0);
    final sinhVal = sinh(pi * (1.0 - 2.0 * newY / n));
    final newLat = atan(sinhVal) * 180.0 / pi;

    setState(() {
      _centerLon = (_centerLon + dLon).clamp(-180.0, 180.0);
      _centerLat = newLat.clamp(-85.0511, 85.0511);
      _panDeltaX += details.delta.dx;
      _panDeltaY += details.delta.dy;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isInteractive) return;
    setState(() => _isDragging = false);
    EtoleHaptics.selection();
    widget.onCoordinatesChanged?.call(OsmCoordinates(_centerLat, _centerLon));
  }

  void _onTapUp(TapUpDetails details, Size mapSize) {
    if (!widget.isInteractive) return;

    final centerPixX = mapSize.width / 2.0;
    final centerPixY = mapSize.height / 2.0;
    final dx = details.localPosition.dx - centerPixX;
    final dy = details.localPosition.dy - centerPixY;

    final n = 1 << _zoom;
    final dLon = dx / (256.0 * n) * 360.0;

    final currentLatRad = _centerLat * pi / 180.0;
    final currentY =
        (1.0 - log(tan(currentLatRad) + 1.0 / cos(currentLatRad)) / pi) /
        2.0 *
        n;
    final newY = currentY + (dy / 256.0);
    final sinhVal = sinh(pi * (1.0 - 2.0 * newY / n));
    final newLat = atan(sinhVal) * 180.0 / pi;

    setState(() {
      _centerLon = (_centerLon + dLon).clamp(-180.0, 180.0);
      _centerLat = newLat.clamp(-85.0511, 85.0511);
    });

    EtoleHaptics.selection();
    widget.onCoordinatesChanged?.call(OsmCoordinates(_centerLat, _centerLon));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = widget.height;
        final mapSize = Size(width, height);

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1318),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // 1. OSM Tile Grid Renderer
                GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  onTapUp: (details) => _onTapUp(details, mapSize),
                  child: _OsmTileLayer(
                    centerLat: _centerLat,
                    centerLon: _centerLon,
                    zoom: _zoom,
                    mapSize: mapSize,
                  ),
                ),

                // 2. Center Draggable Pin with Pulsing Shadow
                Center(
                  child: IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(0, _isDragging ? -14 : -18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.6),
                                  blurRadius: _isDragging ? 14 : 8,
                                  spreadRadius: _isDragging ? 3 : 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              size: 36,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                          // Subtle drop pin shadow on map surface
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: _isDragging ? 18 : 10,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: _isDragging ? 0.25 : 0.45,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Coordinate Pill (Top Left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1318).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pin_drop_rounded,
                          size: 11,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_centerLat.toStringAsFixed(4)}, ${_centerLon.toStringAsFixed(4)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Map Zoom & Action Controls (Right side)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onUseMyLocation != null) ...[
                        _buildMapActionButton(
                          icon: Icons.my_location_rounded,
                          tooltip: 'My Location',
                          onTap: widget.onUseMyLocation!,
                          accent: true,
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (widget.isInteractive) ...[
                        _buildMapActionButton(
                          icon: Icons.add_rounded,
                          tooltip: 'Zoom In',
                          onTap: _zoomIn,
                        ),
                        const SizedBox(height: 4),
                        _buildMapActionButton(
                          icon: Icons.remove_rounded,
                          tooltip: 'Zoom Out',
                          onTap: _zoomOut,
                        ),
                      ],
                    ],
                  ),
                ),

                // 5. OpenStreetMap Legal Attribution (Bottom Left)
                Positioned(
                  bottom: 6,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '© OpenStreetMap contributors',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool accent = false,
  }) {
    return Material(
      color: accent
          ? const Color(0xFFF59E0B).withValues(alpha: 0.9)
          : const Color(0xFF161C24).withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: accent
                  ? const Color(0xFFF59E0B)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: accent ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  static double sinh(double x) => (exp(x) - exp(-x)) / 2.0;
}

/// Renders the 256x256 OpenStreetMap tiles in Web Mercator
class _OsmTileLayer extends StatelessWidget {
  final double centerLat;
  final double centerLon;
  final int zoom;
  final Size mapSize;

  const _OsmTileLayer({
    required this.centerLat,
    required this.centerLon,
    required this.zoom,
    required this.mapSize,
  });

  @override
  Widget build(BuildContext context) {
    final n = 1 << zoom;

    // Center tile coordinate in floating point
    final centerTileX = (centerLon + 180.0) / 360.0 * n;
    final latRad = centerLat * pi / 180.0;
    final centerTileY =
        (1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / pi) / 2.0 * n;

    // Viewport tile range
    final tilesXHalf = (mapSize.width / 2.0) / 256.0;
    final tilesYHalf = (mapSize.height / 2.0) / 256.0;

    final minTileX = (centerTileX - tilesXHalf - 0.5).floor();
    final maxTileX = (centerTileX + tilesXHalf + 0.5).ceil();
    final minTileY = (centerTileY - tilesYHalf - 0.5).floor();
    final maxTileY = (centerTileY + tilesYHalf + 0.5).ceil();

    final centerPixX = mapSize.width / 2.0;
    final centerPixY = mapSize.height / 2.0;

    final tileWidgets = <Widget>[];

    for (int tx = minTileX; tx <= maxTileX; tx++) {
      for (int ty = minTileY; ty <= maxTileY; ty++) {
        // Tile wraps around horizontally (longitude)
        final wrappedX = (tx % n + n) % n;
        if (ty < 0 || ty >= n) continue;

        // Position of tile top-left on screen
        final left = centerPixX + (tx - centerTileX) * 256.0;
        final top = centerPixY + (ty - centerTileY) * 256.0;

        tileWidgets.add(
          Positioned(
            left: left,
            top: top,
            width: 256,
            height: 256,
            child: _CachedOsmTile(zoom: zoom, x: wrappedX, y: ty),
          ),
        );
      }
    }

    return Stack(children: tileWidgets);
  }
}

/// Fetches and caches individual 256x256 OpenStreetMap tiles to disk and memory
class _CachedOsmTile extends StatefulWidget {
  final int zoom;
  final int x;
  final int y;

  const _CachedOsmTile({required this.zoom, required this.x, required this.y});

  @override
  State<_CachedOsmTile> createState() => _CachedOsmTileState();
}

class _CachedOsmTileState extends State<_CachedOsmTile> {
  static final Map<String, Uint8List> _memTileCache = {};
  Uint8List? _tileBytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadTile();
  }

  @override
  void didUpdateWidget(covariant _CachedOsmTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoom != widget.zoom ||
        oldWidget.x != widget.x ||
        oldWidget.y != widget.y) {
      _loadTile();
    }
  }

  Future<void> _loadTile() async {
    final key = '${widget.zoom}_${widget.x}_${widget.y}';
    if (_memTileCache.containsKey(key)) {
      if (mounted) setState(() => _tileBytes = _memTileCache[key]);
      return;
    }

    // Check disk cache in app cache directory
    try {
      final cacheDir = await getTemporaryDirectory();
      final tileFile = File(
        '${cacheDir.path}/osm_tiles/${widget.zoom}/${widget.x}_${widget.y}.png',
      );

      if (await tileFile.exists()) {
        final bytes = await tileFile.readAsBytes();
        _memTileCache[key] = bytes;
        if (mounted) setState(() => _tileBytes = bytes);
        return;
      }

      // Download tile from OpenStreetMap with mandatory User-Agent
      final url = Uri.parse(
        'https://tile.openstreetmap.org/${widget.zoom}/${widget.x}/${widget.y}.png',
      );
      final resp = await http
          .get(url, headers: {'User-Agent': OsmLocationService.userAgent})
          .timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        final bytes = resp.bodyBytes;
        _memTileCache[key] = bytes;
        if (mounted) setState(() => _tileBytes = bytes);

        // Save to disk asynchronously
        tileFile.create(recursive: true).then((f) => f.writeAsBytes(bytes));
      } else {
        if (mounted) setState(() => _failed = true);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tileBytes != null) {
      return Image.memory(
        _tileBytes!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
      );
    }

    // Dark obsidian grid tile while loading or if offline
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11161D),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
          width: 0.5,
        ),
      ),
      child: Center(
        child: _failed
            ? const Icon(
                Icons.grid_4x4_rounded,
                size: 20,
                color: Colors.white12,
              )
            : const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Color(0x33F59E0B),
                ),
              ),
      ),
    );
  }
}
