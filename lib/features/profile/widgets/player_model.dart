import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hypixel_tracker/domain/entities/player.dart';
import 'package:hypixel_tracker/domain/entities/player_skin.dart';
import 'package:hypixel_tracker/domain/repositories/player_repository.dart';
import 'package:hypixel_tracker/features/profile/widgets/player_head.dart';

// The player's skin on a 3D Minecraft body that turns slowly by itself and
// can be spun with a finger. Shows the flat head render until the skin is
// loaded, or when it cannot be.
class PlayerModel extends StatefulWidget {
  const PlayerModel({
    super.key,
    required this.player,
    required this.repository,
    this.width = 96,
    this.height = 160,
  });

  final Player player;
  final PlayerRepository repository;
  final double width;
  final double height;

  @override
  State<PlayerModel> createState() => _PlayerModelState();
}

class _PlayerModelState extends State<PlayerModel>
    with SingleTickerProviderStateMixin {
  static const _spinSpeed = 0.6; // radians per second
  static const _dragSpeed = 0.012; // radians per pixel dragged
  static const _startYaw = -0.5; // a three-quarter view
  // After a pause (tab hidden), turn on from where it was, not jump.
  static const _maxStep = 0.1; // seconds

  late final Ticker _ticker;
  final _yaw = ValueNotifier(_startYaw);
  Duration _lastTick = Duration.zero;
  bool _dragging = false;

  ui.Image? _texture;
  bool _slim = false;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    // Started once there is a skin to turn.
    _ticker = createTicker(_spin);
    _loadSkin();
  }

  @override
  void didUpdateWidget(PlayerModel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player.uuid != widget.player.uuid) _loadSkin();
  }

  Future<void> _loadSkin() async {
    _stopListening();
    // No setState: called from initState, or before a rebuild anyway.
    _texture = null;

    final PlayerSkin? skin;
    try {
      skin = await widget.repository.loadSkin(widget.player);
    } catch (_) {
      return; // The head render stays.
    }
    if (!mounted || skin == null) return;
    // Read here: the null check does not carry into the listener.
    final slim = skin.slim;

    final stream = NetworkImage(skin.url).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (image, _) {
        if (mounted) {
          setState(() {
            _texture = image.image;
            _slim = slim;
          });
          if (!_ticker.isActive) _ticker.start();
        }
      },
      onError: (_, _) {}, // The head render stays.
    );
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _stopListening() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  void _spin(Duration elapsed) {
    final step = min((elapsed - _lastTick).inMicroseconds / 1e6, _maxStep);
    _lastTick = elapsed;
    if (!_dragging && _texture != null) _yaw.value += _spinSpeed * step;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stopListening();
    _yaw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texture = _texture;

    return Semantics(
      image: true,
      label: '${widget.player.name} in 3D',
      excludeSemantics: true,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: texture == null
            ? Center(child: PlayerHead(uuid: widget.player.uuid))
            : GestureDetector(
                onHorizontalDragStart: (_) => _dragging = true,
                onHorizontalDragUpdate: (details) =>
                    _yaw.value += details.delta.dx * _dragSpeed,
                onHorizontalDragEnd: (_) => _dragging = false,
                onHorizontalDragCancel: () => _dragging = false,
                // Repaints on its own every frame: keep it off the rest.
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _ModelPainter(
                      texture: texture,
                      slim: _slim,
                      yaw: _yaw,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

typedef _Vec = (double, double, double);

// One face of a box: the part of the skin it shows, and where it sits in
// space. A texture pixel (x, y) lands at origin + x * right + y * down.
class _Face {
  const _Face(this.source, this.origin, this.right, this.down, this.normal);

  final Rect source;
  final _Vec origin;
  final _Vec right;
  final _Vec down;
  final _Vec normal; // points outwards
}

// A cuboid of the body, e.g. the head, with its skin cut as Minecraft does:
// top and bottom on the first row, then right, front, left and back.
class _Box {
  _Box({
    required int u,
    required int v,
    required int width,
    required int height,
    required int depth,
    required _Vec min,
    double inflate = 0,
  }) : center = (min.$1 + width / 2, min.$2 + height / 2, min.$3 + depth / 2),
       faces = _faces(u, v, width, height, depth, min, inflate);

  final _Vec center;
  final List<_Face> faces;

  static List<_Face> _faces(
    int u,
    int v,
    int w,
    int h,
    int d,
    _Vec min,
    double inflate,
  ) {
    final (x0, y0, z0) = (min.$1 - inflate, min.$2 - inflate, min.$3 - inflate);
    final (x1, y1, z1) = (
      min.$1 + w + inflate,
      min.$2 + h + inflate,
      min.$3 + d + inflate,
    );
    // An outer layer is a bit bigger than the skin pixels it shows.
    final (sx, sy, sz) = ((x1 - x0) / w, (y1 - y0) / h, (z1 - z0) / d);
    Rect rect(int left, int top, int width, int height) => Rect.fromLTWH(
      left.toDouble(),
      top.toDouble(),
      width.toDouble(),
      height.toDouble(),
    );

    return [
      // Top and bottom.
      _Face(
        rect(u + d, v, w, d),
        (x0, y0, z0),
        (sx, 0, 0),
        (0, 0, sz),
        (0, -1, 0),
      ),
      _Face(
        rect(u + d + w, v, w, d),
        (x0, y1, z0),
        (sx, 0, 0),
        (0, 0, sz),
        (0, 1, 0),
      ),
      // The player's right side, on the left as they face us.
      _Face(
        rect(u, v + d, d, h),
        (x0, y0, z0),
        (0, 0, sz),
        (0, sy, 0),
        (-1, 0, 0),
      ),
      _Face(
        rect(u + d, v + d, w, h),
        (x0, y0, z1),
        (sx, 0, 0),
        (0, sy, 0),
        (0, 0, 1),
      ),
      _Face(
        rect(u + d + w, v + d, d, h),
        (x1, y0, z1),
        (0, 0, -sz),
        (0, sy, 0),
        (1, 0, 0),
      ),
      _Face(
        rect(u + 2 * d + w, v + d, w, h),
        (x1, y0, z0),
        (-sx, 0, 0),
        (0, sy, 0),
        (0, 0, -1),
      ),
    ];
  }
}

// One part of the body: the skin box, and the outer layer (hat, jacket,
// sleeves, trousers) drawn over it.
class _Part {
  const _Part(this.inner, this.outer);

  final _Box inner;
  final _Box? outer;
}

// Draws the body with the painter's algorithm: the parts furthest away
// first, and only the faces turned towards the viewer.
class _ModelPainter extends CustomPainter {
  _ModelPainter({required this.texture, required this.slim, required this.yaw})
    : parts = _body(slim: slim, legacy: texture.height == 32),
      super(repaint: yaw);

  final ui.Image texture;
  final bool slim;
  final ValueNotifier<double> yaw;
  final List<_Part> parts;

  // Model units are skin pixels; the body is 32 tall, the margin leaves
  // room for the perspective.
  static const _modelHeight = 38.0;
  static const _pitch = -0.25; // looks slightly down on the player
  static const _cameraDistance = 900.0; // in screen pixels
  // Faces overlap a hair, so no seam shows between them.
  static const _bleed = 0.03;

  static const _outerLayer = 0.25;
  static const _hatLayer = 0.5;

  // Body coordinates: x to the viewer's right, y down, z towards the
  // viewer, the centre of the body at the origin.
  static List<_Part> _body({required bool slim, required bool legacy}) {
    final arm = slim ? 3 : 4;

    _Part part(
      (int, int) skin,
      (int, int)? layer,
      (int, int, int) size,
      _Vec min, {
      double inflate = _outerLayer,
    }) {
      final (w, h, d) = size;
      _Box box((int, int) uv, double inflate) => _Box(
        u: uv.$1,
        v: uv.$2,
        width: w,
        height: h,
        depth: d,
        min: min,
        inflate: inflate,
      );
      return _Part(box(skin, 0), layer == null ? null : box(layer, inflate));
    }

    // Old 64x32 skins have no left limbs nor outer layers but the hat:
    // the left limbs reuse the right ones.
    return [
      part((0, 0), (32, 0), (8, 8, 8), (-4, -16, -4), inflate: _hatLayer),
      part((16, 16), legacy ? null : (16, 32), (8, 12, 4), (-4, -8, -2)),
      part((40, 16), legacy ? null : (40, 32), (arm, 12, 4), (
        -4.0 - arm,
        -8,
        -2,
      )),
      part(
        legacy ? (40, 16) : (32, 48),
        legacy ? null : (48, 48),
        (arm, 12, 4),
        (4, -8, -2),
      ),
      part((0, 16), legacy ? null : (0, 32), (4, 12, 4), (-4, 4, -2)),
      part(
        legacy ? (0, 16) : (16, 48),
        legacy ? null : (0, 48),
        (4, 12, 4),
        (0, 4, -2),
      ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rotation = Matrix4.rotationX(_pitch)
        .multiplied(Matrix4.rotationY(yaw.value));
    final perspective = Matrix4.identity()
      ..setEntry(3, 2, -1 / _cameraDistance);
    final scale = size.height / _modelHeight;
    final view = Matrix4.translationValues(size.width / 2, size.height / 2, 0)
        .multiplied(perspective)
        .multiplied(Matrix4.diagonal3Values(scale, scale, scale))
        .multiplied(rotation);

    final paint = Paint()..filterQuality = FilterQuality.none;
    final sorted = [...parts]
      ..sort(
        (a, b) => _apply(
          rotation,
          a.inner.center,
        ).$3.compareTo(_apply(rotation, b.inner.center).$3),
      );

    for (final part in sorted) {
      for (final box in [part.inner, ?part.outer]) {
        for (final face in box.faces) {
          // Facing away: hidden behind the rest of its box.
          if (_apply(rotation, face.normal, point: false).$3 <= 0) continue;
          _drawFace(canvas, view, face, paint);
        }
      }
    }
  }

  void _drawFace(Canvas canvas, Matrix4 view, _Face face, Paint paint) {
    final (r, d, n, o) = (face.right, face.down, face.normal, face.origin);
    // Maps the face's texture pixels, from its top-left corner, into space.
    final placement = Matrix4(
      r.$1,
      r.$2,
      r.$3,
      0, //
      d.$1,
      d.$2,
      d.$3,
      0, //
      n.$1,
      n.$2,
      n.$3,
      0, //
      o.$1,
      o.$2,
      o.$3,
      1, //
    );
    final source = face.source;

    canvas
      ..save()
      ..transform(view.multiplied(placement).storage)
      ..drawImageRect(
        texture,
        source,
        Rect.fromLTWH(
          -_bleed,
          -_bleed,
          source.width + 2 * _bleed,
          source.height + 2 * _bleed,
        ),
        paint,
      )
      ..restore();
  }

  // [matrix] applied to a point, or to a direction when [point] is false.
  static _Vec _apply(Matrix4 matrix, _Vec v, {bool point = true}) {
    final m = matrix.storage;
    final w = point ? 1.0 : 0.0;
    return (
      m[0] * v.$1 + m[4] * v.$2 + m[8] * v.$3 + m[12] * w,
      m[1] * v.$1 + m[5] * v.$2 + m[9] * v.$3 + m[13] * w,
      m[2] * v.$1 + m[6] * v.$2 + m[10] * v.$3 + m[14] * w,
    );
  }

  @override
  bool shouldRepaint(_ModelPainter oldDelegate) {
    return oldDelegate.texture != texture || oldDelegate.slim != slim;
  }
}
