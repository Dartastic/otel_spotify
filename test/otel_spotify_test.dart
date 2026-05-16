// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_spotify/otel_spotify.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_spotify-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('search.search records types + total', () async {
    await tracedSpotify<String>(
      operation: 'search.search',
      invoke: () async => const SpotifyCallResult(
        value: 'ok',
        result: SpotifyResult(
          surface: 'web_api',
          market: 'US',
          searchTypes: ['track', 'artist'],
          searchTotal: 540,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('spotify search.search')!);
    expect(a['spotify.search.total'], 540);
  });

  test('player.startResumePlayback records device + state', () async {
    await tracedSpotify<String>(
      operation: 'player.startResumePlayback',
      invoke: () async => const SpotifyCallResult(
        value: 'ok',
        result: SpotifyResult(
          surface: 'player',
          deviceId: 'd_1',
          deviceKind: 'Speaker',
          playbackState: 'playing',
          shuffleState: true,
          repeatState: 'context',
        ),
      ),
    );
    final a = attrsOf(
      spans.findSpanByName('spotify player.startResumePlayback')!,
    );
    expect(a['spotify.player.device.kind'], 'Speaker');
    expect(a['spotify.player.repeat'], 'context');
  });

  test('missing scope sets span error', () async {
    await tracedSpotify<String>(
      operation: 'me.getTopArtists',
      invoke: () async => const SpotifyCallResult(
        value: 'ok',
        result: SpotifyResult(requiredScopeMissing: true),
      ),
    );
    expect(
      spans.findSpanByName('spotify me.getTopArtists')!.status,
      SpanStatusCode.Error,
    );
  });

  test('429 retry-after recorded', () async {
    await tracedSpotify<String>(
      operation: 'tracks.get',
      invoke: () async => const SpotifyCallResult(
        value: 'ok',
        result: SpotifyResult(statusCode: 429, retryAfterSec: 30),
      ),
    );
    final s = spans.findSpanByName('spotify tracks.get')!;
    expect(s.status, SpanStatusCode.Error);
    expect(attrsOf(s)['spotify.retry_after_sec'], 30);
  });

  test('suppression skips spans', () async {
    await runWithoutSpotifyInstrumentationAsync(() async {
      await tracedSpotify<String>(
        operation: 'auth.token',
        invoke: () async => const SpotifyCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('spotify '), isEmpty);
  });
}
