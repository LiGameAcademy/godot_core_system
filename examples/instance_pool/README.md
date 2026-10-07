# Instance pool example

Open `res://addons/godot_core_system/examples/instance_pool/instance_pool.tscn` and run with F6. No AutoLoad, game assets or nested project is required.

1. Spawn pair: two actors appear with independent runtime Gradient copies.
2. Tint A: A turns red; B and the shared template keep their original color.
3. Recycle both, then spawn again: the same node identities are reused; activation resets both colors.
4. Clear cached instances: returned objects are freed; active leases survive Clear.
5. Leave the scene: the owner closes its pool; fresh active children are released by the scene.

The caller instantiates a missing actor, attaches and activates it; it hides/detaches before recycling. The pool only manages storage and ownership. Read [API and checks](../../docs/systems/instance_pool.md) for capacity, rejection, resource duplication and final Close behavior.

Both versions pass nine actual button/lifecycle checks. The example deliberately uses two actors; large rendered measurements belong to the host game, where scene cost is representative.
