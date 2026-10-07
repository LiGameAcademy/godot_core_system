# Legacy facade demonstration

Run audio_demo.tscn in a standalone host. This scene explicitly creates only missing Music/SFX/Voice/Ambient buses, claims their controls plus Master, injects that scope into its local AudioManager, and removes only its own added buses on exit. The plugin itself does not create or remove buses.

Space replaces/fades music, S plays SFX, V plays voice, M changes Music bus gain, Escape stops. The updated demo has no pending scripted demonstration timers and does not require CoreSystem. Its original audio assets are reused. Do not run alongside an application that already owns these bus controls.

For bilingual playback/configuration checks and the minimal sample, use ../audio/README.md. The legacy facade requires configure_mix before volume controls; paths are borrowed through its explicit local cache. Preferences are opt-in through CoreAudioPreferences, never loaded by playback.
