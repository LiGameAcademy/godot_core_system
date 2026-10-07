extends RefCounted

## 只选择 locale，不修改 TranslationServer 或用户配置。
static func normalize(locale: String) -> String:
	var pattern: RegEx = RegEx.new()
	pattern.compile("^[a-zA-Z]{2,3}(?:[_-][a-zA-Z0-9]{2,8})*$")
	var trimmed: String = locale.strip_edges()
	if pattern.search(trimmed) == null:
		return ""
	var normalized: String = TranslationServer.standardize_locale(trimmed)
	if not TranslationServer.get_all_languages().has(normalized.get_slice("_", 0)):
		return ""
	return normalized

## 原生相似度最高者优先；并列时按 locale 字符顺序稳定选择。
static func match_locale(requested: String, available: PackedStringArray) -> String:
	var normalized: String = normalize(requested)
	if normalized.is_empty():
		return ""
	var ordered: PackedStringArray = available.duplicate()
	ordered.sort()
	var best: String = ""
	var best_score: int = 0
	var requested_script: String = _script(normalized)
	for locale: String in ordered:
		var candidate: String = normalize(locale)
		if candidate.is_empty():
			continue
		var candidate_script: String = _script(candidate)
		# 简繁或其它明确文字系统不匹配时，不因语言相同而选中。
		if not requested_script.is_empty() and not candidate_script.is_empty() and requested_script != candidate_script:
			continue
		var score: int = TranslationServer.compare_locales(normalized, candidate)
		if score > best_score:
			best_score = score
			best = candidate
	return best

static func _script(locale: String) -> String:
	var parts: PackedStringArray = locale.split("_")
	for part: String in parts:
		if part.length() == 4 and not part.is_valid_int():
			return part
	# 4.2 的规范化没有 add_defaults 参数，明确补充常见中文地区的文字含义。
	if parts[0] == "zh":
		for part: String in parts:
			if part in ["TW", "HK", "MO"]:
				return "Hant"
			if part in ["CN", "SG"]:
				return "Hans"
	return ""
