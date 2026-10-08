# Localization module (issue #92 trial)

This optional service manages locale preferences and startup restoration. Translation data and text lookup remain owned by Godot's TranslationServer, native CSV/PO importers, tr(), and tr_n().

Enable `godot_core_system/module_enable/localization_manager` explicitly; it defaults to false. Configure your native translations in Project Settings / Localization before startup. Enable ConfigManager and use a writable configuration path if persistence is needed. The service does not enable a disabled ConfigManager.

```gdscript
func choose_language(preference: String) -> void:
    var manager: CoreSystem.LocalizationManager = CoreSystem.localization_manager
    if manager == null:
        return
    var error: Error = manager.set_preferred_locale(preference, true)
    if error != OK:
        push_warning(error_string(error))
```

- `get_preferred_locale()`: requested choice, including "auto"; stored as [localization] preferred_locale.
- `get_locale()`: current native locale, read directly from TranslationServer.
- `get_available_locales()`: sorted native loaded locales.
- `resolve_locale(preference, system_locale="")`: native similarity matching with deterministic lexical ties; distinct explicit writing systems do not match each other. Common Chinese regions imply Hans or Hant. Auto uses the system locale, then the project fallback; explicit unavailable selections fail.
- `get_startup_error()`: restore result. CLI --language and the project test locale preserve native startup overrides while still reading the saved choice.
- `locale_changed(old_locale, new_locale)`: actual changes only, including external native changes observed through translation notifications.
- `preference_changed(preference)`: changed choice only.
- `preference_save_failed(preference, error)`: missing configuration, malformed saved type, or failed disk save.

`set_preferred_locale(preference, persist=false)` switches first and saves only when requested. ERR_UNCONFIGURED, ERR_INVALID_DATA and ERR_FILE_CANT_WRITE from persistence do not roll back the effective locale. Reentrant switching from signal callbacks returns ERR_BUSY. Invalid or unavailable choices leave the previous choice and locale intact.

Standalone use: instantiate `source/localization_system/localization_manager.tscn` and inject an existing ConfigManager through `configure_persistence()` before adding it to the tree. Do not run multiple startup preference owners. If resources are loaded later, explicitly call `restore_preference()` again.

The module never clears or unloads host translations and never restores a previous global locale on exit. Static controls use native automatic translation; their owning UI refreshes cached dynamic text on NOTIFICATION_TRANSLATION_CHANGED. Disable automatic translation for player input. Native missing-message fallback, contexts, plural rules and formatting remain native responsibilities.

Run `examples/localization_demo/localization_demo.tscn` with the CoreSystem localization switch disabled: the example owns a standalone service. Try English, simplified/traditional Chinese, auto, coins, editable player name, and preference restoration after restart. ConfigManager is optional. The demo preserves an already registered copy of its translation resource.

`demo.csv` is the editable source; the three committed .translation resources are native generated outputs. Reimport after CSV edits. Godot may automatically register these demo translations in project settings: remove the demo entries when integrating your own game. The example uses a SystemFont; ship appropriate fonts in a real export.

Tested with Godot 4.7.2 Mono, using GDScript and an actual OpenGL render. Unit scenes require an isolated host with no global translation resources and localization disabled; startup checks use the fixture modes documented in the [Chinese guide](localization_system_zh.md). Older engines, exported builds, PO contexts/plurals, pseudolocalization and a real game integration remain unverified. Existing typed dictionaries prevent assuming repository-wide 4.2 compatibility from plugin.cfg. Existing module shutdown/dependency issues remain outside this change.

This introduces a public API and global locale behavior; retain the PR for user acceptance and manual merge. Refs #92.
