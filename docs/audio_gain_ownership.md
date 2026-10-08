# Audio gain application (#69)

Master and category volumes are applied only by their AudioServer buses.
SFX/Voice players use the per-call volume. Music players start at neutral
0 dB and their fade-in ends at 0 dB; fades operate on the player independently
of category settings. Effective gain is master x category x per-call/fade gain.
Changing a category therefore affects existing and newly started players alike.

The same settings now produce a louder result than the old squared-category
behavior. Listen in the actual game and adjust balance if needed.

```sh
godot --headless --path /path/to/host res://addons/godot_core_system/test/unit/audio_gain_checks.tscn
```

The regression checks actual player/bus dB values, SFX/Voice/Music, category
changes, new players, music fade completion, and zero per-call volume.
It uses the bundled click.ogg, which must be imported in the host.
PASS / exit 0 verifies gain arithmetic, not subjective audio quality.
