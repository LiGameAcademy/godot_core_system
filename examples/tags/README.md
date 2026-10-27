# Local tag example

Open tags_example.tscn and run it in a host containing this plugin. No AutoLoad, game scripts or external assets are required.

- Toggle stun: add/remove state.stunned; the model rejects actions while stunned.
- Toggle shield: add/remove effect.shield independently of stun.
- Try action: the rule increments its counter only when it can act.
- Reset local model: clear runtime facts and counter, then restore unit.scout.

Each instance owns its tags. The model has no UI dependency; the root script only coordinates buttons and displays model results. Signals/events are disconnected on exit. There is no automatic saving, object search or engine pause.

See [CoreTags](../../docs/systems/core_tags.md) for semantics, language differences and automated verification commands.