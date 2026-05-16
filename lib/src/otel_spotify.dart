// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_spotify_suppression.dart';

const _tracerName = 'dartastic_otel_libs_spotify';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class SpotifyResult {
  const SpotifyResult({
    this.surface,
    this.market,
    this.entityKind,
    this.entityId,
    this.entityName,
    this.itemCount,
    this.durationMs,
    this.shuffleState,
    this.repeatState,
    this.deviceId,
    this.deviceKind,
    this.playbackState,
    this.searchTypes,
    this.searchTotal,
    this.scopesGranted,
    this.requiredScopeMissing,
    this.retryAfterSec,
    this.errorMessage,
    this.statusCode,
  });

  /// `web_api`, `accounts`, `player`, `partner`.
  final String? surface;

  /// ISO 3166-1 alpha-2 market (`US`, `GB`, `BR`, ...).
  final String? market;

  /// `track`, `album`, `artist`, `playlist`, `show`, `episode`,
  /// `audiobook`, `chapter`, `user`, `category`.
  final String? entityKind;

  /// Spotify URI (`spotify:track:xxx`) or bare id.
  final String? entityId;
  final String? entityName;

  /// Result item count for paginated endpoints.
  final int? itemCount;

  /// Track / episode duration in ms.
  final int? durationMs;

  // ── Player ─────────────────────────────────────────────────────
  final bool? shuffleState;

  /// `off`, `track`, `context`.
  final String? repeatState;

  final String? deviceId;

  /// `Computer`, `Smartphone`, `Speaker`, `TV`, `AVR`, `STB`,
  /// `AudioDongle`, `GameConsole`, `CastVideo`, `CastAudio`, `Automobile`,
  /// `Unknown`.
  final String? deviceKind;

  /// `playing`, `paused`, `stopped`.
  final String? playbackState;

  /// `track,artist,album,playlist,...` types parameter on `search`.
  final List<String>? searchTypes;

  /// `tracks.total + artists.total + ...` aggregate from search response.
  final int? searchTotal;

  /// OAuth scopes granted on the active token.
  final List<String>? scopesGranted;

  /// Endpoint required a scope the token didn't carry.
  final bool? requiredScopeMissing;

  /// Spotify rate-limit retry-after (seconds).
  final int? retryAfterSec;

  final String? errorMessage;
  final int? statusCode;
}

class SpotifyCallResult<T> {
  const SpotifyCallResult({required this.value, this.result});
  final T value;
  final SpotifyResult? result;
}

/// Wraps a Spotify Web API call in a CLIENT span. [operation] is one of
/// `search.search`, `tracks.get`, `tracks.getSeveral`,
/// `albums.get`, `albums.getSeveral`, `albums.getTracks`,
/// `artists.get`, `artists.getAlbums`, `artists.getTopTracks`,
/// `artists.getRelated`, `playlists.get`, `playlists.create`,
/// `playlists.addItems`, `playlists.removeItems`, `playlists.reorder`,
/// `playlists.update`, `shows.get`, `shows.getEpisodes`,
/// `episodes.get`, `audiobooks.get`, `audiobooks.getChapters`,
/// `me.get`, `me.getTopArtists`, `me.getTopTracks`, `me.getRecentlyPlayed`,
/// `me.getFollowing`, `me.follow`, `me.unfollow`,
/// `me.checkFollowing`, `library.getSaved*`, `library.save*`,
/// `library.remove*`, `library.checkSaved*`,
/// `player.getPlaybackState`, `player.transferPlayback`,
/// `player.getAvailableDevices`, `player.getCurrentlyPlaying`,
/// `player.startResumePlayback`, `player.pausePlayback`,
/// `player.skipToNext`, `player.skipToPrevious`,
/// `player.seek`, `player.setRepeatMode`, `player.setVolume`,
/// `player.toggleShuffle`, `player.addToQueue`, `player.getRecentlyPlayed`,
/// `categories.list`, `categories.get`,
/// `browse.getFeaturedPlaylists`, `browse.getNewReleases`,
/// `auth.token`, `auth.refresh`.
Future<T> tracedSpotify<T>({
  required String operation,
  required Future<SpotifyCallResult<T>> Function() invoke,
}) async {
  if (spotifyInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'spotify',
    'rpc.method': operation,
    'spotify.operation': operation,
  };

  final span = _tracer().startSpan(
    'spotify $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.surface != null) {
        extras.add(OTel.attributeString('spotify.surface', res.surface!));
      }
      if (res.market != null) {
        extras.add(OTel.attributeString('spotify.market', res.market!));
      }
      if (res.entityKind != null) {
        extras.add(OTel.attributeString(
          'spotify.entity.kind',
          res.entityKind!,
        ));
      }
      if (res.entityId != null) {
        extras.add(OTel.attributeString(
          'spotify.entity.id',
          res.entityId!,
        ));
      }
      if (res.entityName != null) {
        extras.add(OTel.attributeString(
          'spotify.entity.name',
          res.entityName!,
        ));
      }
      if (res.itemCount != null) {
        extras.add(OTel.attributeInt('spotify.item.count', res.itemCount!));
      }
      if (res.durationMs != null) {
        extras.add(OTel.attributeInt('spotify.duration_ms', res.durationMs!));
      }
      if (res.shuffleState != null) {
        extras.add(OTel.attributeBool(
          'spotify.player.shuffle',
          res.shuffleState!,
        ));
      }
      if (res.repeatState != null) {
        extras.add(OTel.attributeString(
          'spotify.player.repeat',
          res.repeatState!,
        ));
      }
      if (res.deviceId != null) {
        extras.add(OTel.attributeString(
          'spotify.player.device.id',
          res.deviceId!,
        ));
      }
      if (res.deviceKind != null) {
        extras.add(OTel.attributeString(
          'spotify.player.device.kind',
          res.deviceKind!,
        ));
      }
      if (res.playbackState != null) {
        extras.add(OTel.attributeString(
          'spotify.player.state',
          res.playbackState!,
        ));
      }
      if (res.searchTypes != null) {
        extras.add(OTel.attributeStringList(
          'spotify.search.types',
          res.searchTypes!,
        ));
      }
      if (res.searchTotal != null) {
        extras.add(OTel.attributeInt(
          'spotify.search.total',
          res.searchTotal!,
        ));
      }
      if (res.scopesGranted != null) {
        extras.add(OTel.attributeStringList(
          'spotify.scopes.granted',
          res.scopesGranted!,
        ));
      }
      if (res.requiredScopeMissing != null) {
        extras.add(OTel.attributeBool(
          'spotify.scope.missing',
          res.requiredScopeMissing!,
        ));
        if (res.requiredScopeMissing!) {
          span.setStatus(SpanStatusCode.Error, 'Spotify missing scope');
        }
      }
      if (res.retryAfterSec != null) {
        extras.add(OTel.attributeInt(
          'spotify.retry_after_sec',
          res.retryAfterSec!,
        ));
      }
      if (res.errorMessage != null) {
        extras.add(OTel.attributeString(
          'spotify.error.message',
          res.errorMessage!,
        ));
      }
      if (res.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Spotify HTTP ${res.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
