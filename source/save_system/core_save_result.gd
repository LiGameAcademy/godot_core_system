class_name CoreSaveResult
extends RefCounted

## Explicit read/write result; a missing file is OK with found=false.
var error: Error = OK
var found: bool = false
var data: Dictionary = {}
var message: String = ""
var cleanup_error: Error = OK

static func failure(code: Error, detail: String) -> CoreSaveResult:
	var result: CoreSaveResult = CoreSaveResult.new()
	result.error = code
	result.message = detail
	return result
