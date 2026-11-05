// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_spotify/otel_spotify.dart';

/// Traces Spotify Web calls with OpenTelemetry.
///
/// `otel_spotify` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Spotify Web call in
/// [tracedSpotify]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'spotify-example');

  // Wraps a Spotify Web API call in a CLIENT span.
  final spotifyId = await tracedSpotify<String>(
    operation: 'playlists.create',
    invoke: () async {
      // Make the Spotify Web call here, then report what it returned.
      const id = 'spotify_8f3a2c';
      return const SpotifyCallResult(
          value: id,
          result: SpotifyResult(
              surface: 'web_api',
              market: 'US',
              entityKind: 'track',
              entityId: 'spotify:track:3Mtw8f3a2c',
              entityName: 'example',
              itemCount: 3,
              durationMs: 120,
              shuffleState: true,
              repeatState: 'off',
              deviceId: 'device_8f3a2c',
              deviceKind: 'Computer',
              playbackState: 'playing',
              searchTypes: ['standard'],
              searchTotal: 1,
              scopesGranted: ['example'],
              requiredScopeMissing: true,
              retryAfterSec: 0,
              errorMessage: 'example',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedSpotify playlists.create returned $spotifyId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutSpotifyInstrumentationAsync.
  await runWithoutSpotifyInstrumentationAsync(
    () => tracedSpotify<String>(
      operation: 'playlists.create',
      invoke: () async {
        const id = 'spotify_8f3a2c';
        return const SpotifyCallResult(
            value: id,
            result: SpotifyResult(
                surface: 'web_api',
                market: 'US',
                entityKind: 'track',
                entityId: 'spotify:track:3Mtw8f3a2c',
                entityName: 'example',
                itemCount: 3,
                durationMs: 120,
                shuffleState: true,
                repeatState: 'off',
                deviceId: 'device_8f3a2c',
                deviceKind: 'Computer',
                playbackState: 'playing',
                searchTypes: ['standard'],
                searchTotal: 1,
                scopesGranted: ['example'],
                requiredScopeMissing: true,
                retryAfterSec: 0,
                errorMessage: 'example',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
