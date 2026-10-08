# Dictionary keys in JSON/binary saves (#65)

String-key dictionaries retain their existing JSON representation. Dictionaries
with non-String keys now use this local envelope:

```json
{"_type_": 27, "dictionary_format": 2, "entries": [[encoded_key, encoded_value]]}
```

Keys and values both pass through the existing Variant codec. This preserves
integer, StringName and Vector2i keys without JSON converting them to strings,
and distinguishes integer 7 from string "7". Typed dictionaries additionally
retain their existing key/value type metadata. Nested and root dictionaries
use the same rule. StringName values use a TYPE_STRING_NAME tag with a v field.

The new loader accepts the old plain string-key representation and old typed
dictionary envelopes containing dictionary. It cannot recover original key
types from already-corrupted untyped historical files. Old typed integer-key
files still have their old limitations; this change does not invent keys from
ambiguous JSON strings.

Older plugin versions cannot read the new non-string-key envelope: upgrade
readers before using newly written files. dictionary_format versions other than
2 and malformed entries are diagnosed rather than interpreted as ordinary keys.
This local envelope version does not establish a global save-format migration
policy; that decision belongs to #76. Cyclic objects and unsupported Variant
types remain subject to the existing codec's limitations.

Regression command in a writable host with CoreSystem:

```sh
godot --headless --path /path/to/host res://addons/godot_core_system/test/unit/dictionary_key_checks.tscn
```

Expect PASS and exit 0. It covers the JSON intermediate layer and JSON/binary
disk round trips, nested/typed/mixed keys, root dictionaries and legacy
string-key decoding.
