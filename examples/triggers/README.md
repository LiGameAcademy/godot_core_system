# Local trigger example

Open triggers_example.tscn in a host with this plugin. No AutoLoad or game assets are needed.

Toggle the ready tag, try a trigger, toggle enabled and reset the count. The model combines CoreTags with a two-commit CoreTrigger limit. The scene only displays rule results and forwards buttons; each instance owns its own model. Reset preserves readiness and enabled state. Exit disconnects tag notifications, so retaining a model after scene release does not retain or access UI.

The static GD condition reads explicit context and avoids a model/trigger reference cycle. The C# condition is a static lambda over the explicit CoreTags argument. Notifications are local, not global bus events.

See the module documentation for contract and verification commands.
