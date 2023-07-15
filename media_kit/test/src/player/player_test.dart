import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:collection/collection.dart';
import 'package:universal_platform/universal_platform.dart';

import 'package:media_kit/src/models/track.dart';
import 'package:media_kit/src/models/playlist.dart';
import 'package:media_kit/src/models/media/media.dart';
import 'package:media_kit/src/models/audio_device.dart';
import 'package:media_kit/src/models/audio_params.dart';
import 'package:media_kit/src/models/video_params.dart';
import 'package:media_kit/src/models/playlist_mode.dart';

import 'package:media_kit/src/media_kit.dart';
import 'package:media_kit/src/player/player.dart';
import 'package:media_kit/src/player/platform_player.dart';
import 'package:media_kit/src/player/web/player/player.dart';
import 'package:media_kit/src/player/native/player/player.dart';

import '../../common/sources.dart';

void main() {
  setUp(() async {
    MediaKit.ensureInitialized();

    await sources.prepare();

    // For preventing video driver & audio driver initialization errors in unit-tests.
    NativePlayer.test = true;
    // For preventing "DOMException: play() failed because the user didn't interact with the document first." in unit-tests.
    WebPlayer.test = true;
  });
  test(
    'player-platform',
    () {
      final player = Player();
      expect(
        player.platform,
        isA<NativePlayer>(),
      );

      addTearDown(player.dispose);
    },
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-platform',
    () {
      final player = Player();
      expect(
        player.platform,
        isA<WebPlayer>(),
      );

      addTearDown(player.dispose);
    },
    skip: !UniversalPlatform.isWeb,
  );
  test(
    'player-handle',
    () {
      final player = Player();
      expect(
        player.handle,
        completes,
      );

      addTearDown(player.dispose);
    },
  );
  test(
    'player-configuration-ready-callback',
    () {
      final expectReady = expectAsync0(() {});

      final player = Player(
        configuration: PlayerConfiguration(
          ready: () {
            expectReady();
          },
        ),
      );

      addTearDown(player.dispose);
    },
  );
  test(
    'player-open-playable-media',
    () async {
      final player = Player();

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            Playlist(
              [
                Media(sources.platform[0]),
              ],
              index: 0,
            ),
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            true,
            // EOF
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.completed,
        emitsInOrder(
          [
            // Player.open
            false,
            // EOF
            true,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(Media(sources.platform[0]));

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-playlist',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            true,
            // -> 1
            false,
            true,
            // -> 2
            false,
            true,
            // -> 3
            false,
            true,
            // EOF
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.completed,
        emitsInOrder(
          [
            // Player.open
            false,
            // -> 1
            true,
            false,
            // -> 2
            true,
            false,
            // -> 3
            true,
            false,
            // EOF
            true,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(playable);

      await Future.delayed(const Duration(minutes: 1, seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 2)),
  );
  test(
    'player-open-playable-media-play-false',
    () async {
      final player = Player();

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            Playlist(
              [
                Media(sources.platform[0]),
              ],
              index: 0,
            ),
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(
        Media(sources.platform[0]),
        play: false,
      );

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-playlist-play-false',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            playable,
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(playable, play: false);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-media-play-false-play',
    () async {
      final player = Player();

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            Playlist(
              [
                Media(sources.platform[0]),
              ],
              index: 0,
            ),
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            // Player.play
            true,
            // EOF
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.completed,
        emitsInOrder(
          [
            // Player.open
            // Player.play
            false,
            // EOF
            true,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(
        Media(sources.platform[0]),
        play: false,
      );
      await player.play();

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );

  test(
    'player-open-playable-playlist-play-false-play',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            true,
            // -> 1
            false,
            true,
            // -> 2
            false,
            true,
            // -> 3
            false,
            true,
            // EOF
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.completed,
        emitsInOrder(
          [
            // Player.open
            false,
            // -> 1
            true,
            false,
            // -> 2
            true,
            false,
            // -> 3
            true,
            false,
            // EOF
            true,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(playable, play: false);
      await player.play();

      await Future.delayed(const Duration(minutes: 1, seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 2)),
  );
  test(
    'player-open-playable-media-extras',
    () async {
      final player = Player();

      final expectExtras = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<Map<String, dynamic>>());
          final extras = value as Map<String, dynamic>;
          expect(
            MapEquality().equals(
              extras,
              {
                'foo': 'bar',
                'baz': 'qux',
              },
            ),
            true,
          );
        },
      );

      player.stream.playlist.listen((e) {
        if (e.index >= 0) {
          expectExtras(e.medias[0].extras);
        }
      });

      await player.open(
        Media(
          sources.platform[0],
          extras: {
            'foo': 'bar',
            'baz': 'qux',
          },
        ),
      );

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-playlist-extras',
    () async {
      final player = Player();

      final expectExtras = expectAsync2(
        (value, i) {
          print(value);
          expect(value, isA<Map<String, dynamic>>());
          final extras = value as Map<String, dynamic>;
          expect(
            MapEquality().equals(
              extras,
              {
                'i': i.toString(),
              },
            ),
            true,
          );
        },
        count: sources.platform.length,
      );

      player.stream.playlist.listen(
        (e) {
          if (e.index >= 0) {
            expectExtras(
              e.medias[e.index].extras,
              e.index,
            );
          }
        },
      );

      await player.open(
        Playlist(
          [
            for (int i = 0; i < sources.platform.length; i++)
              Media(
                sources.platform[i],
                extras: {
                  'i': i.toString(),
                },
              ),
          ],
        ),
      );

      await Future.delayed(const Duration(minutes: 1));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1, seconds: 30)),
  );
  test(
    'player-open-playable-media-http-headers',
    () async {
      final player = Player();

      final address = '127.0.0.1';
      final port = 8081;

      final expectHTTPHeaders = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<HttpHeaders>());
          final headers = value as HttpHeaders;

          expect(headers.value('X-Foo'), 'Bar');
          expect(headers.value('X-Baz'), 'Qux');
        },
      );

      final expectPlayable = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<Playlist>());
          final playable = value as Playlist;
          expect(
            ListEquality().equals(
              playable.medias,
              [
                Media(
                  'http://$address:$port/0',
                  httpHeaders: {
                    'X-Foo': 'Bar',
                    'X-Baz': 'Qux',
                  },
                ),
              ],
            ),
            true,
          );
        },
      );

      final completed = HashSet<int>();

      final socket = await ServerSocket.bind(address, port);
      final server = HttpServer.listenOn(socket);
      server.listen(
        (e) async {
          final i = int.parse(e.uri.path.split('/').last);
          if (!completed.contains(i)) {
            completed.add(i);
            expectHTTPHeaders(e.headers);
          }
          final path = sources.platform[i];
          e.response.headers.add('Content-Type', 'video/mp4');
          e.response.headers.add('Accept-Ranges', 'bytes');
          File(path).openRead().pipe(e.response);
        },
      );

      player.stream.playlist.listen((e) {
        if (e.index >= 0) {
          expectPlayable(e);
        }
      });

      await player.open(
        Media(
          'http://$address:$port/0',
          httpHeaders: {
            'X-Foo': 'Bar',
            'X-Baz': 'Qux',
          },
        ),
      );

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
      await server.close();
    },
    timeout: Timeout(const Duration(minutes: 1)),
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-open-playable-playlist-http-headers',
    () async {
      final player = Player();

      final address = '127.0.0.1';
      final port = 8082;

      final expectHTTPHeaders = expectAsync2(
        (value, i) {
          print(value);
          expect(value, isA<HttpHeaders>());
          final headers = value as HttpHeaders;
          expect(headers.value('X-Foo'), '$i');
        },
        count: sources.platform.length,
      );
      final expectPlayable = expectAsync2(
        (value, i) {
          print(value);
          expect(value, isA<Playlist>());
          final playable = value as Playlist;
          expect(playable.index, i);
          expect(
            ListEquality().equals(
              playable.medias,
              [
                for (int i = 0; i < sources.platform.length; i++)
                  Media(
                    'http://$address:$port/$i',
                    httpHeaders: {
                      'X-Foo': '$i',
                    },
                  ),
              ],
            ),
            true,
          );
        },
        count: sources.platform.length,
      );

      final completed = HashSet<int>();

      final socket = await ServerSocket.bind(address, port);
      final server = HttpServer.listenOn(socket);
      server.listen(
        (e) async {
          final i = int.parse(e.uri.path.split('/').last);
          if (!completed.contains(i)) {
            completed.add(i);
            expectHTTPHeaders(e.headers, i);
          }
          final data = sources.bytes[i];
          e.response.headers.contentLength = data.length;
          e.response.headers.contentType = ContentType('video', 'mp4');
          e.response.add(data);
          await e.response.flush();
          await e.response.close();
        },
      );

      player.stream.playlist.listen((e) {
        if (e.index >= 0) {
          expectPlayable(e, e.index);
        }
      });

      await player.open(
        Playlist(
          [
            for (int i = 0; i < sources.platform.length; i++)
              Media(
                'http://$address:$port/$i',
                httpHeaders: {
                  'X-Foo': '$i',
                },
              ),
          ],
        ),
      );

      await Future.delayed(const Duration(minutes: 1));

      await player.dispose();
      await server.close();
    },
    timeout: Timeout(const Duration(minutes: 1, seconds: 30)),
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-play-after-completed',
    () async {
      // Only applicable for PlaylistMode.none.

      final completer = Completer();

      final player = Player();

      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            true,
            // EOF
            false,
            // Player.play
            true,
          ],
        ),
      );
      expect(
        player.stream.completed,
        emitsInOrder(
          [
            // Player.open
            false,
            // EOF
            true,
            // Player.play
            false,
          ],
        ),
      );

      player.stream.completed.listen((event) {
        if (!completer.isCompleted) {
          if (event) {
            completer.complete();
          }
        }
      });

      await player.open(Media(sources.platform[0]));

      // Wait for EOF.
      await completer.future;

      final expectPosition = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<Duration>());
        },
        count: 1,
        max: -1,
      );

      player.stream.position.listen((event) async {
        print(event);
        expectPosition(event);
      });

      await Future.delayed(const Duration(seconds: 5));

      // Begin test.

      await player.play();

      // End test.

      await Future.delayed(const Duration(seconds: 5));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-seek-after-completed',
    () async {
      final completer = Completer();

      final player = Player();

      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            true,
            // EOF
            false,
            // Player.seek
            // ---------
          ],
        ),
      );
      expect(
        player.stream.completed,
        emitsInOrder(
          [
            // Player.open
            false,
            // EOF
            true,
            // Player.seek
            false,
          ],
        ),
      );

      player.stream.completed.listen((event) {
        if (!completer.isCompleted) {
          if (event) {
            completer.complete();
          }
        }
      });

      await player.open(Media(sources.platform[0]));

      // Wait for EOF.
      await completer.future;

      final expectPosition = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<Duration>());
          final position = value as Duration;
          expect(position, Duration.zero);
        },
        count: 1,
        max: -1,
      );

      player.stream.position.listen((event) async {
        print(event);
        expectPosition(event);
      });

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      // Begin test.

      await player.seek(Duration.zero);

      // End test.

      await Future.delayed(const Duration(seconds: 5));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-while-playing',
    () async {
      final player = Player();

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            Playlist(
              [
                Media(sources.platform[0]),
              ],
              index: 0,
            ),
            Playlist(
              [
                Media(sources.platform[1]),
              ],
              index: 0,
            ),
          ],
        ),
      );
      expect(
        player.stream.playing,
        emitsInOrder(
          [
            false,
            true,
            false,
            true,
          ],
        ),
      );
      // NOTE: Not emitted when the playable is changed mid-playback. Only upon end of file.
      expect(
        player.stream.completed,
        emitsInOrder(
          [
            false,
            true,
          ],
        ),
      );

      await player.open(Media(sources.platform[0]));

      await Future.delayed(const Duration(seconds: 5));

      await player.open(Media(sources.platform[1]));

      addTearDown(player.dispose);
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-playlist-non-zero-index',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
        index: sources.platform.length - 1,
      );

      expect(
        player.stream.playlist,
        emits(
          playable,
        ),
      );

      await player.open(playable);

      addTearDown(player.dispose);
    },
    timeout: Timeout(const Duration(minutes: 1)),
    // TODO: Flaky!
    skip: true,
  );
  test(
    'player-audio-devices',
    () async {
      final player = Player();

      final expectAudioDevices = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<List<AudioDevice>>());
          final devices = value as List<AudioDevice>;
          expect(devices, isNotEmpty);
          expect(devices.first, equals(AudioDevice.auto()));
        },
        count: 1,
        max: -1,
      );

      player.stream.audioDevices.listen((event) async {
        expectAudioDevices(event);
      });

      addTearDown(player.dispose);
    },
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-set-audio-device',
    () async {
      final player = Player();

      final devices = await player.stream.audioDevices.first;

      if (devices.length > 1) {
        expect(devices, isNotEmpty);
        expect(devices.first, equals(AudioDevice.auto()));

        final expectAudioDevice = expectAsync2(
          (device, i) {
            print(device);
            expect(device, isA<AudioDevice>());
            expect(device, equals(devices[i as int]));
          },
          count: devices.length,
        );

        int? index;

        player.stream.audioDevice.listen((event) async {
          expectAudioDevice(event, index);
        });

        for (int i = devices.length - 1; i >= 0; i--) {
          index = i;

          await player.setAudioDevice(devices[i]);

          await Future.delayed(const Duration(seconds: 1));
        }
      }

      addTearDown(player.dispose);
    },
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-set-audio-device',
    () async {
      final player = Player();

      expect(
        player.setAudioDevice(AudioDevice.auto()),
        throwsUnsupportedError,
      );

      addTearDown(player.dispose);
    },
    skip: !UniversalPlatform.isWeb,
  );
  test(
    'player-set-volume',
    () async {
      final player = Player();

      final expectVolume = expectAsync2(
        (volume, i) {
          print(volume);
          expect(volume, isA<double>());
          expect(i, isA<int>());
          volume = volume as double;
          i = i as int;
          expect(
            /* This round() is solely needed because floating-point arithmetic on JavaScript is retarded. */
            volume.round(),
            equals(i),
          );
        },
        count: 100,
      );

      int? index;

      player.stream.volume.listen((event) {
        expectVolume(event, index);
      });

      for (int i = 0; i < 100; i++) {
        index = i;

        await player.setVolume(i.toDouble());

        await Future.delayed(const Duration(milliseconds: 100));
      }

      addTearDown(player.dispose);
    },
  );
  test(
    'player-set-rate',
    () async {
      final player = Player();

      final test = List.generate(10, (index) => 0.25 * (index + 1));

      final expectRate = expectAsync2(
        (rate, i) {
          print(rate);
          expect(rate, isA<double>());
          expect(i, isA<int>());
          expect(rate, equals(test[i as int]));
        },
        count: test.length,
      );

      int? index;

      player.stream.rate.listen((event) {
        expectRate(event, index);
      });

      for (int i = 0; i < test.length; i++) {
        index = i;

        await player.setRate(test[i]);

        await Future.delayed(const Duration(milliseconds: 20));
      }

      addTearDown(player.dispose);
    },
  );
  test(
    'player-set-pitch-disabled',
    () async {
      final player = Player();

      expect(player.setPitch(1.0), throwsArgumentError);

      addTearDown(player.dispose);
    },
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-set-pitch-enabled',
    () async {
      final player = Player(configuration: PlayerConfiguration(pitch: true));

      final test = List.generate(10, (index) => 0.25 * (index + 1));

      final expectPitch = expectAsync2(
        (pitch, i) {
          print(pitch);
          expect(pitch, isA<double>());
          expect(i, isA<int>());
          expect(pitch, equals(test[i as int]));
        },
        count: test.length,
      );

      int? index;

      player.stream.pitch.listen((event) {
        expectPitch(event, index);
      });

      for (int i = 0; i < test.length; i++) {
        index = i;

        await player.setPitch(test[i]);

        await Future.delayed(const Duration(milliseconds: 20));
      }

      addTearDown(player.dispose);
    },
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-set-pitch-enabled',
    () async {
      final player = Player(configuration: PlayerConfiguration(pitch: true));

      expect(
        player.setPitch(1.0),
        throwsUnsupportedError,
      );

      addTearDown(player.dispose);
    },
    skip: !UniversalPlatform.isWeb,
  );
  test(
    'player-set-playlist-mode',
    () async {
      final player = Player();

      expect(
        player.stream.playlistMode,
        emitsInOrder(
          [
            ...PlaylistMode.values,
          ],
        ),
      );

      for (final value in PlaylistMode.values) {
        await player.setPlaylistMode(value);
      }

      addTearDown(player.dispose);
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-jump',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );
      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            TypeMatcher<Playlist>().having(
              (playlist) => playlist.index,
              'index',
              equals(0),
            ),
            // Player.jump
            TypeMatcher<Playlist>().having(
              (playlist) => playlist.index,
              'index',
              equals(2),
            ),
          ],
        ),
      );

      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(2);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-move',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.move
            Playlist(move(playable.medias, 1, 3)),
          ],
        ),
      );

      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.move(1, 3);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-index-transitions-playlist-mode-none',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // index: 0 -> sources.platform.length - 1
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),
            emitsDone,
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.none);
      await player.open(playable);

      await Future.delayed(const Duration(minutes: 1));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1, seconds: 30)),
  );
  test(
    'player-index-transitions-playlist-mode-single',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // index: 0 (does not change)
            playable.copyWith(index: 0),
            emitsDone,
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.single);
      await player.open(playable);

      await Future.delayed(const Duration(minutes: 1));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1, seconds: 30)),
  );
  test(
    'player-index-transitions-playlist-mode-loop',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // index: 0 -> sources.platform.length - 1
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),

            // must loop back to index: 0

            // index: 0 -> sources.platform.length - 1
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.loop);
      await player.open(playable);

      await Future.delayed(const Duration(minutes: 2, seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 5)),
  );
  test(
    'player-next-playlist-mode-none',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // index: 0 -> sources.platform.length - 1
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),
            emitsDone,
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.none);
      await player.open(playable);

      final timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        try {
          await player.next();
        } catch (_) {}
      });

      await Future.delayed(const Duration(seconds: 15));

      timer.cancel();
      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-next-playlist-mode-single',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // index: 0 -> sources.platform.length - 1
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),
            emitsDone,
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.single);
      await player.open(playable);

      final timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        try {
          await player.next();
        } catch (_) {}
      });

      await Future.delayed(const Duration(seconds: 15));

      timer.cancel();
      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-next-playlist-mode-loop',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // index: 0 -> sources.platform.length - 1
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),

            // must loop back to index: 0

            // index: 0 -> sources.platform.length - 1
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.loop);
      await player.open(playable);

      final timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        try {
          await player.next();
        } catch (_) {}
      });

      await Future.delayed(const Duration(seconds: 15));

      timer.cancel();
      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-previous-playlist-mode-none',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            playable,
            // index: sources.platform.length - 1 -> 0
            for (int i = sources.platform.length - 1; i >= 0; i--)
              playable.copyWith(index: i),
            // Cannot test (since index keeps transitioning):
            // emitsDone,
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.none);
      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(sources.platform.length - 1);

      final timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        try {
          await player.previous();
        } catch (_) {}
      });

      await Future.delayed(const Duration(seconds: 45));

      timer.cancel();
      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-previous-playlist-mode-single',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            playable,
            // index: sources.platform.length - 1 -> 0
            for (int i = sources.platform.length - 1; i >= 0; i--)
              playable.copyWith(index: i),
            // Cannot test (since index keeps transitioning):
            // emitsDone,
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.single);
      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(sources.platform.length - 1);

      final timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        try {
          await player.previous();
        } catch (_) {}
      });

      await Future.delayed(const Duration(seconds: 45));

      timer.cancel();
      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-previous-playlist-mode-loop',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );
      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            playable,
            // index: sources.platform.length - 1 -> 0
            for (int i = sources.platform.length - 1; i >= 0; i--)
              playable.copyWith(index: i),

            // must loop back to index: sources.platform.length - 1

            for (int i = sources.platform.length - 1; i >= 0; i--)
              playable.copyWith(index: i),
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.loop);
      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(sources.platform.length - 1);

      final timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        try {
          await player.previous();
        } catch (_) {}
      });

      await Future.delayed(const Duration(seconds: 45));

      timer.cancel();
      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-add',
    () async {
      final player = Player();

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            Playlist(
              [
                Media(sources.platform[0]),
              ],
              index: 0,
            ),
            // Player.add
            Playlist(
              [
                Media(sources.platform[0]),
                Media(sources.platform[1]),
              ],
              index: 0,
            ),
            // index transition
            Playlist(
              [
                Media(sources.platform[0]),
                Media(sources.platform[1]),
              ],
              index: 1,
            ),
            emitsDone,
          ],
        ),
      );

      await player.open(Media(sources.platform[0]));

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.add(Media(sources.platform[1]));

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-remove-before-current-index',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.jump
            playable.copyWith(index: 1),
            // Player.remove
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != 0) Media(sources.platform[i]),
              ],
              index: 0,
            ),
            // index transition
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != 0) Media(sources.platform[i]),
              ],
              index: 1,
            ),
          ],
        ),
      );

      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(1);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.remove(0);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-remove-after-current-index',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.remove
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != 1) Media(sources.platform[i]),
              ],
              index: 0,
            ),
            // index transition
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != 1) Media(sources.platform[i]),
              ],
              index: 1,
            ),
          ],
        ),
      );

      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.remove(1);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-remove-current-index',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.remove
            Playlist(
              [
                // The next item should start playing & index will not increment because the current index is removed.
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != 0) Media(sources.platform[i]),
              ],
              index: 0,
            ),
            // index transition
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != 0) Media(sources.platform[i]),
              ],
              index: 1,
            ),
          ],
        ),
      );

      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.remove(0);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-remove-current-index-stop-playlist-mode-none',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.jump
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  Media(sources.platform[i]),
              ],
              index: sources.platform.length - 1,
            ),
            // Player.remove
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != sources.platform.length - 1)
                    Media(sources.platform[i]),
              ],
              index: sources.platform.length - 2,
            ),
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.none);
      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(sources.platform.length - 1);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.remove(sources.platform.length - 1);

      await Future.delayed(const Duration(seconds: 45));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-remove-current-index-stop-playlist-mode-single',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.jump
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  Media(sources.platform[i]),
              ],
              index: sources.platform.length - 1,
            ),
            // Player.remove
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != sources.platform.length - 1)
                    Media(sources.platform[i]),
              ],
              index: sources.platform.length - 2,
            ),
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.single);
      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(sources.platform.length - 1);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.remove(sources.platform.length - 1);

      await Future.delayed(const Duration(seconds: 45));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-remove-current-index-stop-playlist-mode-loop',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.jump
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  Media(sources.platform[i]),
              ],
              index: sources.platform.length - 1,
            ),
            // Player.remove
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != sources.platform.length - 1)
                    Media(sources.platform[i]),
              ],
              // must loop back to index: 0
              index: 0,
            ),
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.loop);
      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(sources.platform.length - 1);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.remove(sources.platform.length - 1);

      await Future.delayed(const Duration(seconds: 45));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-set-rate-negative',
    () async {
      final player = Player();

      expect(
        () async => await player.setRate(-1.0),
        throwsArgumentError,
      );

      addTearDown(player.dispose);
    },
  );
  test(
    'player-set-pitch-negative',
    () async {
      final player = Player(configuration: PlayerConfiguration(pitch: true));

      expect(
        () async => await player.setPitch(-1.0),
        throwsArgumentError,
      );

      addTearDown(player.dispose);
    },
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-set-pitch-negative',
    () async {
      final player = Player(configuration: PlayerConfiguration(pitch: true));

      expect(
        () async => await player.setPitch(-1.0),
        throwsUnsupportedError,
      );

      addTearDown(player.dispose);
    },
    skip: !UniversalPlatform.isWeb,
  );
  test(
    'player-set-shuffle',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      player.stream.playlist.listen(
        (e) {
          print(e.medias.join('\n'));
          print('------------------------------');
        },
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.setShuffle /w true
            TypeMatcher<Playlist>().having(
              (event) => event.medias.toSet(),
              'medias',
              equals(playable.medias.toSet()),
            ),
            // Player.setShuffle /w false
            playable,
          ],
        ),
      );

      await player.open(playable);

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.setShuffle(true);

      await Future.delayed(const Duration(seconds: 5));

      // VOLUNTARY DELAY.
      await player.setShuffle(false);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    // TODO: Flaky!
    skip: true,
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-set-shuffle-consecutive',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      player.stream.playlist.listen(
        (e) {
          print(e.medias.join('\n'));
          print('------------------------------');
        },
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.setShuffle /w true
            TypeMatcher<Playlist>().having(
              (event) => event.medias.toSet(),
              'medias',
              equals(playable.medias.toSet()),
            ),
            // Player.setShuffle /w false
            playable,
          ],
        ),
      );

      await player.open(playable);

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.setShuffle(true);
      await player.setShuffle(true);
      await player.setShuffle(true);
      await player.setShuffle(true);
      await player.setShuffle(true);

      await Future.delayed(const Duration(seconds: 5));

      // VOLUNTARY DELAY.
      await player.setShuffle(false);
      await player.setShuffle(false);
      await player.setShuffle(false);
      await player.setShuffle(false);
      await player.setShuffle(false);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    // TODO: Flaky!
    skip: true,
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-buffering-file',
    () async {
      final player = Player();

      player.stream.buffering.listen((e) => print(e));

      expect(
        player.stream.buffering,
        emitsInOrder(
          [
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // EOF
            true,
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(Media(sources.file[0]));

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-buffering-network',
    () async {
      final player = Player();

      player.stream.buffering.listen((e) => print(e));

      expect(
        player.stream.buffering,
        emitsInOrder(
          [
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // EOF
            true,
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(Media(sources.network[0]));

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-buffering-file-play-false',
    () async {
      final player = Player();

      player.stream.buffering.listen((e) => print(e));

      expect(
        player.stream.buffering,
        emitsInOrder(
          [
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(
        Media(sources.file[0]),
        play: false,
      );

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-buffering-network-play-false',
    () async {
      final player = Player();

      player.stream.buffering.listen((e) => print(e));

      expect(
        player.stream.buffering,
        emitsInOrder(
          [
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(
        Media(sources.network[0]),
        play: false,
      );

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-buffering-upon-seek',
    () async {
      final player = Player();

      player.stream.buffering.listen((e) => print(e));

      expect(
        player.stream.buffering,
        emitsInOrder(
          [
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // Player.seek: buffering = true
            true,
            // Player.seek: buffering = false
            false,
            // EOF
            true,
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      // Seek to the end of the stream to trigger buffering.
      player.stream.duration.listen((event) async {
        if (event > Duration.zero) {
          // VOLUNTARY DELAY.
          await Future.delayed(const Duration(seconds: 5));
          await player.seek(event - const Duration(seconds: 10));
        }
      });

      await player.open(
        Media(
          'https://github.com/alexmercerind/media_kit/assets/28951144/efb4057c-6fd3-4644-a0b1-42d5fb420ce9',
        ),
      );

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-buffering-playlist',
    () async {
      final player = Player();

      player.stream.playlist.listen((e) => print(e.index));
      player.stream.completed.listen((e) => print('completed: $e'));
      player.stream.buffering.listen((e) => print('buffering: $e'));

      expect(
        player.stream.buffering,
        emitsInOrder(
          [
            // 0
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // EOF
            true,
            false,

            // 1
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // EOF
            true,
            false,

            // 2
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // EOF
            true,
            false,

            // 3
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // EOF
            true,
            false,

            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(
        Playlist(
          [
            for (int i = 0; i < sources.network.length; i++)
              Media(sources.network[i]),
          ],
        ),
      );

      await Future.delayed(const Duration(minutes: 1, seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 2)),
  );
  test(
    'player-stop',
    () async {
      final player = Player();

      await player.open(Media(sources.platform[0]));

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.stop();

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      print(player.state);

      expect(player.state.playlist, equals(Playlist([])));
      expect(player.state.playing, equals(false));
      expect(player.state.completed, equals(false));
      expect(player.state.position, equals(Duration.zero));
      expect(player.state.duration, equals(Duration.zero));
      expect(player.state.buffering, equals(false));
      expect(player.state.buffer, equals(Duration.zero));
      expect(player.state.audioParams, equals(const AudioParams()));
      expect(player.state.videoParams, equals(const VideoParams()));
      expect(player.state.audioBitrate, equals(null));
      expect(player.state.track, equals(const Track()));
      expect(player.state.tracks, equals(const Tracks()));
      expect(player.state.width, equals(null));
      expect(player.state.height, equals(null));
      expect(
        ListEquality().equals(
          player.state.subtitle,
          [
            '',
            '',
          ],
        ),
        equals(true),
      );

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 2)),
  );
  test(
    'player-stop-open',
    () async {
      final player = Player();

      await player.open(Media(sources.platform[0]));

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.stop();

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      final expectPosition = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<Duration>());
        },
        count: 1,
        max: -1,
      );

      player.stream.position.listen((event) async {
        print(event);
        expectPosition(event);
      });

      await player.open(Media(sources.platform[0]));

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 2)),
  );
  test(
    'player-screenshot',
    () async {
      final player = Player();

      await player.open(Media(sources.platform[0]));

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      final screenshot = await player.screenshot();

      expect(screenshot, isNotNull);
      expect(screenshot, isA<Uint8List>());
      expect(screenshot?.length ?? 0, greaterThan(0));

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 2)),
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-screenshot-format',
    () async {
      final player = Player();

      await player.open(Media(sources.platform[0]));

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      final screenshot = await player.screenshot(format: 'image/png');

      expect(screenshot, isNotNull);
      expect(screenshot, isA<Uint8List>());
      expect(screenshot?.length ?? 0, greaterThan(0));

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 2)),
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-screenshot',
    () async {
      final player = Player();

      await player.open(Media(sources.platform[0]));

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      // CORS
      final screenshot = await player.screenshot();

      expect(screenshot, isNull);

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 2)),
    skip: !UniversalPlatform.isWeb,
  );
  test(
    'player-screenshot-format',
    () async {
      final player = Player();

      await player.open(Media(sources.platform[0]));

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      // CORS
      final screenshot = await player.screenshot(format: 'image/png');

      expect(screenshot, isNull);

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 2)),
    skip: !UniversalPlatform.isWeb,
  );
  test(
    'player-screenshot-argument-error',
    () async {
      final player = Player();

      await player.open(Media(sources.platform[0]));

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      expect(
        () async => await player.screenshot(format: 'abc'),
        throwsArgumentError,
      );
      expect(
        () async => await player.screenshot(format: 'xyz'),
        throwsArgumentError,
      );

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 2)),
  );
  test(
    'player-subtitle',
    () async {
      final player = Player();

      player.stream.tracks.listen((event) {
        print(event);
      });
      player.stream.subtitle.listen((subtitle) {
        print(subtitle);
      });

      expect(
        player.stream.tracks,
        emitsInOrder(
          [
            Tracks(
              video: [
                VideoTrack('auto', null, null),
                VideoTrack('no', null, null),
                VideoTrack('1', null, null)
              ],
              audio: [
                AudioTrack('auto', null, null),
                AudioTrack('no', null, null),
                AudioTrack('1', null, null),
                AudioTrack('2', 'Commentary', 'eng')
              ],
              subtitle: [
                SubtitleTrack('auto', null, null),
                SubtitleTrack('no', null, null),
                SubtitleTrack('1', null, 'eng'),
                SubtitleTrack('2', null, 'hun'),
                SubtitleTrack('3', null, 'ger'),
                SubtitleTrack('4', null, 'fre'),
                SubtitleTrack('5', null, 'spa'),
                SubtitleTrack('6', null, 'ita'),
                SubtitleTrack('7', null, 'jpn'),
                SubtitleTrack('8', null, 'null'),
              ],
            ),
            Tracks(),
            emitsDone,
          ],
        ),
      );

      expect(
        player.stream.subtitle,
        emitsInOrder(
          [
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['...the colossus of Rhodes!', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['No!', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                [
                  'The colossus of Rhodes\nand it is here just for you Proog.',
                  ''
                ],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['It is there...', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['I\'m telling you,\nEmo...', ''],
              ),
              'subtitle',
              isTrue,
            ),
            emitsDone,
          ],
        ),
      );

      await player.open(
        Media(
          'https://github.com/ietf-wg-cellar/matroska-test-files/raw/master/test_files/test5.mkv',
        ),
      );

      await Future.delayed(const Duration(minutes: 1));

      await player.dispose();
    },
    skip: UniversalPlatform.isWeb,
    timeout: Timeout(const Duration(minutes: 2)),
  );
  test(
    'player-tracks-playlist',
    () async {
      final player = Player();

      player.stream.tracks.listen((event) {
        print(event);
      });

      expect(
        player.stream.tracks,
        emitsInOrder(
          [
            Tracks(
              video: [
                VideoTrack('auto', null, null),
                VideoTrack('no', null, null),
                VideoTrack('1', null, null)
              ],
              audio: [
                AudioTrack('auto', null, null),
                AudioTrack('no', null, null),
                AudioTrack('1', null, null),
                AudioTrack('2', 'Commentary', 'eng')
              ],
              subtitle: [
                SubtitleTrack('auto', null, null),
                SubtitleTrack('no', null, null),
                SubtitleTrack('1', null, 'eng'),
                SubtitleTrack('2', null, 'hun'),
                SubtitleTrack('3', null, 'ger'),
                SubtitleTrack('4', null, 'fre'),
                SubtitleTrack('5', null, 'spa'),
                SubtitleTrack('6', null, 'ita'),
                SubtitleTrack('7', null, 'jpn'),
                SubtitleTrack('8', null, 'null'),
              ],
            ),
            Tracks(),
            Tracks(
              video: [
                VideoTrack('auto', null, null),
                VideoTrack('no', null, null),
                VideoTrack('1', null, null)
              ],
              audio: [
                AudioTrack('auto', null, null),
                AudioTrack('no', null, null),
                AudioTrack('1', null, null),
                AudioTrack('2', 'Commentary', 'eng')
              ],
              subtitle: [
                SubtitleTrack('auto', null, null),
                SubtitleTrack('no', null, null),
                SubtitleTrack('1', null, 'eng'),
                SubtitleTrack('2', null, 'hun'),
                SubtitleTrack('3', null, 'ger'),
                SubtitleTrack('4', null, 'fre'),
                SubtitleTrack('5', null, 'spa'),
                SubtitleTrack('6', null, 'ita'),
                SubtitleTrack('7', null, 'jpn'),
                SubtitleTrack('8', null, 'null'),
              ],
            ),
            Tracks(),
            emitsDone,
          ],
        ),
      );

      await player.open(
        Playlist(
          [
            Media(
              'https://github.com/ietf-wg-cellar/matroska-test-files/raw/master/test_files/test5.mkv',
            ),
            Media(
              'https://github.com/ietf-wg-cellar/matroska-test-files/raw/master/test_files/test5.mkv',
            ),
          ],
        ),
      );

      await Future.delayed(const Duration(minutes: 2));

      await player.dispose();
    },
    skip: UniversalPlatform.isWeb,
    timeout: Timeout(const Duration(minutes: 3)),
  );
  test(
    'player-external-set-subtitle-track',
    () async {
      final player = Player(
        configuration: const PlayerConfiguration(
          logLevel: MPVLogLevel.v,
        ),
      );

      player.stream.log.listen((event) {
        print(event);
      });
      player.stream.track.listen((event) {
        print(event);
      });
      player.stream.subtitle.listen((event) {
        print(event);
      });

      expect(
        player.stream.track,
        emitsInOrder(
          [
            Track(
              video: VideoTrack.auto(),
              audio: AudioTrack.auto(),
              subtitle: SubtitleTrack.external(
                'https://www.iandevlin.com/html5test/webvtt/upc-video-subtitles-en.vtt',
                title: 'English',
                language: 'en',
              ),
            ),
            Track(
              video: VideoTrack.auto(),
              audio: AudioTrack.auto(),
              subtitle: SubtitleTrack.auto(),
            ),
            // Player.dispose
            Track(
              video: VideoTrack.no(),
              audio: AudioTrack.auto(),
              subtitle: SubtitleTrack.auto(),
            ),
            Track(
              video: VideoTrack.no(),
              audio: AudioTrack.no(),
              subtitle: SubtitleTrack.auto(),
            ),
            Track(
              video: VideoTrack.no(),
              audio: AudioTrack.no(),
              subtitle: SubtitleTrack.no(),
            ),
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.subtitle,
        emitsInOrder(
          [
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['Everyone wants the most from life', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                [
                  'Like internet experiences that are rich and entertaining',
                  ''
                ],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['Phone conversations where people truly connect', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                [
                  'Your favourite TV programmes ready to watch at the touch of a button',
                  ''
                ],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                [
                  'Which is why we are bringing TV, internet and phone together in one super package',
                  ''
                ],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['One simple way to get everything', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['UPC', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['Simply for everyone', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            emitsDone,
          ],
        ),
      );

      await player.open(
        Media(
          'https://www.iandevlin.com/html5test/webvtt/v/upc-tobymanley.theora.ogg',
        ),
      );
      await player.setSubtitleTrack(
        SubtitleTrack.external(
          'https://www.iandevlin.com/html5test/webvtt/upc-video-subtitles-en.vtt',
          title: 'English',
          language: 'en',
        ),
      );

      await Future.delayed(const Duration(minutes: 1));

      await player.dispose();
    },
    skip: UniversalPlatform.isWeb,
    timeout: Timeout(const Duration(minutes: 2)),
  );
  test(
    'player-external-set-subtitle-track',
    () async {
      final webvtt = '''WEBVTT FILE

1
00:00:03.500 --> 00:00:05.000 D:vertical A:start
Everyone wants the most from life

2
00:00:06.000 --> 00:00:09.000 A:start
Like internet experiences that are rich <b>and</b> entertaining

3
00:00:11.000 --> 00:00:14.000 A:end
Phone conversations where people truly <c.highlight>connect</c>

4
00:00:14.500 --> 00:00:18.000
Your favourite TV programmes ready to watch at the touch of a button

5
00:00:19.000 --> 00:00:24.000
Which is why we are bringing TV, internet and phone together in <c.highlight>one</c> super package

6
00:00:24.500 --> 00:00:26.000
<c.highlight>One</c> simple way to get everything

7
00:00:26.500 --> 00:00:27.500 L:12%
UPC

8
00:00:28.000 --> 00:00:30.000 L:75%
Simply for <u>everyone</u>
''';

      final player = Player();

      player.stream.track.listen((event) {
        print(event);
      });
      player.stream.subtitle.listen((event) {
        print(event);
      });

      expect(
        player.stream.track,
        emitsInOrder(
          [
            Track(
              video: VideoTrack.auto(),
              audio: AudioTrack.auto(),
              subtitle: SubtitleTrack.external(
                webvtt,
                title: 'English',
                language: 'en',
              ),
            ),
            Track(
              video: VideoTrack.auto(),
              audio: AudioTrack.auto(),
              subtitle: SubtitleTrack.auto(),
            ),
            // Player.dispose
            Track(
              video: VideoTrack.no(),
              audio: AudioTrack.auto(),
              subtitle: SubtitleTrack.auto(),
            ),
            Track(
              video: VideoTrack.no(),
              audio: AudioTrack.no(),
              subtitle: SubtitleTrack.auto(),
            ),
            Track(
              video: VideoTrack.no(),
              audio: AudioTrack.no(),
              subtitle: SubtitleTrack.no(),
            ),
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.subtitle,
        emitsInOrder(
          [
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['Everyone wants the most from life', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                [
                  'Like internet experiences that are rich and entertaining',
                  ''
                ],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['Phone conversations where people truly connect', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                [
                  'Your favourite TV programmes ready to watch at the touch of a button',
                  ''
                ],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                [
                  'Which is why we are bringing TV, internet and phone together in one super package',
                  ''
                ],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['One simple way to get everything', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['UPC', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['Simply for everyone', ''],
              ),
              'subtitle',
              isTrue,
            ),
            TypeMatcher<List<String>>().having(
              (subtitle) => ListEquality().equals(
                subtitle,
                ['', ''],
              ),
              'subtitle',
              isTrue,
            ),
            emitsDone,
          ],
        ),
      );

      await player.open(
        Media(
          'https://www.iandevlin.com/html5test/webvtt/v/upc-tobymanley.theora.ogg',
        ),
      );
      await player.setSubtitleTrack(
        SubtitleTrack.external(
          webvtt,
          title: 'English',
          language: 'en',
        ),
      );

      await Future.delayed(const Duration(minutes: 1));

      await player.dispose();
    },
    skip: !UniversalPlatform.isWeb,
    timeout: Timeout(const Duration(minutes: 2)),
  );
}

List<T> move<T>(List<T> list, int from, int to) {
  final map = SplayTreeMap<double, T>.from(
    list.asMap().map((key, value) => MapEntry(key * 1.0, value)),
  );
  final item = map.remove(from * 1.0);
  if (item != null) {
    map[to - 0.5] = item;
  }
  return map.values.toList();
}
