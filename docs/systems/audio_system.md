# Independent audio

Playback depends on Godot, without CoreSystem, logging or configuration. Install the audio scripts and matching CoreAudio/CoreMusic scenes; parents explicitly supply streams and existing bus names after Ready on the main thread. These are non-spatial players; positional sound uses Godot's AudioStreamPlayer2D/3D.

## Sounds

CoreAudio.Play/play returns bool; PlayVoice/play_voice returns a borrowed AudioStreamPlayer or null. The scene owns players: do not free them, change their streams or stop them directly. Use StopAll/stop_all. Natural completion clears the stream reference and allows reuse. Imported clip loop flags are respected. Choose non-looping clips for finite sounds.

MaxVoices/max_voices defaults to 8, read at Ready. Capacity exhaustion declines without interrupting existing voices. C# validates 1–64 and throws for invalid capacity or stream/bus/volume arguments; GD clamps capacity and returns false/null for invalid playback. C# not-ready calls throw InvalidOperationException; GD declines them. Paused instances decline requests. The reusable scene uses Pausable, while directly constructed nodes inherit their parent mode; configure Always before adding a scene for pause-menu sounds. StopAll clears streams, retaining reusable players until owner exit.

## Music

CoreMusic.Play/play(stream, bus = Master, fadeSeconds/fade_seconds = 0.5, loop = true, volumeDb/volume_db = 0) returns Error. Stop/stop accepts fade duration, default 0. Invalid finite/range inputs return InvalidParameter, absent buses DoesNotExist, unavailable lifecycle or unsupported streams Unavailable. Rejected playback preserves the existing track.

Two owned voices bound overlap. Rapid replacement retires the older outgoing voice and fades from the other voice's actual level. Faded stop retires both voices; StopAll stops immediately. IsPlaying/is_playing, IsTransitioning/is_transitioning and CurrentStream/current_stream expose observations. Fades use real ticks and Always processing, independent of pause and Engine.TimeScale. A stalled frame advances the transition when processing resumes.

WAV, OggVorbis, MP3 and AudioStreamPlaylist are supported. Music duplicates the resource and changes private loop settings, preserving the original. Playlist control affects its root Loop flag; nested clips retain their import flags. Choose non-looping playlist clips when progression is required. Owned copies are released on replacement, stop and exit.

## Bus ownership

CoreAudioBusScope exclusively claims existing named buses among participating scopes. It captures volume/mute, restores by name on Close/close, and releases claims. Use one application owner for a shared mix. Keep names/layout stable while claimed. Direct AudioServer writes are outside this protocol. C# invalid construction throws; GD invalid construction produces a closed scope. All operations require the main thread.

SetVolume/set_volume accepts finite linear gain 0–1; zero uses a -80 dB floor. SetMuted/set_muted handles mute separately. Setters return Error. Unavailable GetVolume throws in C#; get_volume returns -1 in GD. Close is idempotent and restores buses still present. Category gain belongs to the bus; an extra clip gain belongs to the player. A bus at 0.5 and player at 0 dB produce 0.5, not 0.25 (issue #69 regression).

## Optional preferences

CoreAudioPreferences requires CoreConfig (GD config_manager.gd) only when explicitly used. Load configuration first, then Restore/restore(config, scope). Save/save writes the current levels and saves explicitly. Playback never performs IO.

Section audio uses lower-case bus name plus _volume. Case-colliding names are rejected before mutation. Restore validates every value (integer/float, finite 0–1) before applying any; missing values default to 1. Save failure is returned independently of active playback. Configuration memory may already hold the attempted values; retry is explicit. Mute is not serialized by this adapter.

## Verification

The examples/audio directory contains a standalone scene without AutoLoads or game dependencies. Core checks cover gain once, capacity, interrupted transitions, pause/speed, resource isolation, preference validation, save failure and cleanup. Native audio playback retires asynchronously on the mixer thread after stop; test hosts allow a short real-time drain before quitting. This is not a gameplay timing dependency. Headless checks do not establish subjective sound quality or exported-build acceptance.

## Legacy GD AudioManager migration

The path-based audio_manager.gd facade retains Music/SFX/Voice/Ambient categories and local preload caching. It owns CoreMusic and a shared 32-voice CoreAudio. configure_mix borrows a caller-owned scope; the caller closes it. Volume setters return false without a scope. Configure category buses in the host layout.

Remove reliance on implicit CoreSystem configuration/logger lookup, automatic bus creation, automatic preference IO and assignment to audio_node_root (now read-only self). Music returns Error; missing resources fail explicitly. Sound/voice/ambient return borrowed players and decline at the common capacity instead of growing without bound. Category gain is applied once on the bus. This compatibility facade is GD-only; both languages share the aligned core.

The original audio_demo now explicitly creates only missing category buses, owns their scope and restores/removes them on exit. See examples/audio_demo/README.md. The new examples/audio scene uses Master only and synthesizes its own tone.
