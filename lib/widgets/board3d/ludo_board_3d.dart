import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../models/game_state.dart';
import '../../providers/game_provider.dart';
import '../ludo_board_widget.dart';
import 'board_snapshot.dart';

/// Le plateau en 3D : bois, céramique émaillée, figurines, ombres portées.
///
/// La scène est une page Three.js embarquée (assets/board3d/index.html, dont
/// les sources sont dans board3d/) affichée dans une WebView. Le jeu reste
/// entièrement ici : à chaque changement de [GameProvider], on envoie à la
/// page un [boardSnapshot] ; elle renvoie le pion touché, qu'on joue avec
/// [GameProvider.movePawn] comme le fait le plateau 2D.
///
/// Tant que la page n'est pas prête, et partout où elle ne peut pas tourner
/// (web, bureau, WebGL absent), c'est le plateau 2D [LudoBoardWidget] qui
/// s'affiche.
class LudoBoard3D extends StatefulWidget {
  const LudoBoard3D({super.key});

  /// Les plateformes où la WebView est disponible.
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  State<LudoBoard3D> createState() => _LudoBoard3DState();
}

class _LudoBoard3DState extends State<LudoBoard3D> {
  late final WebViewController _controller;
  GameProvider? _provider;
  bool _ready = false;
  bool _failed = false;
  String? _lastSent;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('LudoBoard', onMessageReceived: _onPageMessage)
      ..setNavigationDelegate(NavigationDelegate(
        onWebResourceError: (error) {
          if (error.isForMainFrame ?? true) _fail();
        },
      ))
      ..loadFlutterAsset('assets/board3d/index.html');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<GameProvider>();
    if (provider != _provider) {
      _provider?.removeListener(_push);
      _provider = provider..addListener(_push);
      _push();
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_push);
    super.dispose();
  }

  void _onPageMessage(JavaScriptMessage message) {
    final Object? data;
    try {
      data = jsonDecode(message.message);
    } on FormatException {
      return;
    }
    if (data is! Map) return;
    switch (data['type']) {
      case 'ready':
        if (!mounted) return;
        setState(() => _ready = true);
        _lastSent = null;
        _push();
      case 'error':
        _fail();
      case 'tap':
        final pawn = data['pawn'];
        final state = _provider?.state;
        if (pawn is int && state?.phase == GamePhase.choosingPawn) {
          _provider!.movePawn(pawn);
        }
    }
  }

  void _fail() {
    if (!mounted || _failed) return;
    setState(() => _failed = true);
  }

  /// Envoie l'état à la page, seulement s'il a changé : le fournisseur
  /// notifie aussi pendant le lancer de dé, qui ne touche pas au plateau.
  void _push() {
    final provider = _provider;
    final state = provider?.state;
    if (!_ready || _failed || provider == null || state == null) return;
    final json = jsonEncode(boardSnapshot(
      state,
      lastMove: provider.lastMove,
      moveVersion: provider.moveVersion,
      lastCapture: provider.lastCaptureEffect,
      captureVersion: provider.captureVersion,
    ));
    if (json == _lastSent) return;
    _lastSent = json;
    _controller.runJavaScript('window.ludoBoard.apply($json)').catchError((_) {
      _fail();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const LudoBoardWidget();
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!_ready) const LudoBoardWidget(),
        AnimatedOpacity(
          opacity: _ready ? 1 : 0,
          duration: const Duration(milliseconds: 350),
          child: IgnorePointer(
            ignoring: !_ready,
            child: WebViewWidget(controller: _controller),
          ),
        ),
      ],
    );
  }
}
