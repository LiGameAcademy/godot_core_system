extends Resource

## Read-only configuration; runtime slots and pending state belong to instances.
@export var directory: String = "user://saves"
@export var group: StringName = &"saveable"
@export var format: StringName = &"resource"
@export var schema_version: int = 1
@export var legacy_schema_version: int = 1
@export var game_version: String = "1.0.0"
@export var encryption_key: String = ""
@export var auto_save_enabled: bool = true
@export var auto_save_interval: float = 300.0
@export var auto_save_prefix: String = "auto_"
@export var max_auto_saves: int = 3
