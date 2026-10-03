extends Node
## Analyses the player-entered name so Milka can react to how it is written.
##
## Nothing here touches the UI: `analyze()` returns plain data and the dialogue
## only reads the boolean traits that GameState keeps.

const MIN_LENGTH: int = 1
const MAX_LENGTH: int = 24

const MATH_SYMBOLS: String = "+-*/=<>^%~"
const SPECIAL_SYMBOLS: String = "!@#$&()[]{}|\\:;\"'?,.`_"

## Returns a dictionary of boolean traits plus a few counts.
static func analyze(raw_name: String) -> Dictionary:
	var player_name: String = raw_name.strip_edges()
	var letters: int = 0
	var digits: int = 0
	var spaces: int = 0
	var math: int = 0
	var special: int = 0
	var emoji: int = 0
	var uppercase: int = 0
	var lowercase: int = 0
	var non_latin: int = 0

	for i: int in player_name.length():
		var c: String = player_name[i]
		var code: int = player_name.unicode_at(i)
		if c == " ":
			spaces += 1
		elif c >= "0" and c <= "9":
			digits += 1
		elif MATH_SYMBOLS.contains(c):
			math += 1
		elif _is_math_unicode(code):
			math += 1
		elif SPECIAL_SYMBOLS.contains(c):
			special += 1
		elif _is_emoji(code):
			emoji += 1
		elif _is_letter(code):
			letters += 1
			if c == c.to_upper() and c != c.to_lower():
				uppercase += 1
			else:
				lowercase += 1
			if code > 0x24F:
				non_latin += 1
		else:
			special += 1

	var first: String = player_name.substr(0, 1)
	var first_code: int = player_name.unicode_at(0) if player_name.length() > 0 else 0
	var first_is_letter: bool = _is_letter(first_code)

	var traits: Dictionary = {
		"length": player_name.length(),
		"letters": letters,
		"digits": digits,
		"emoji": emoji,
		"math": math,
		"special": special,
		"spaces": spaces,
		"is_empty": player_name.is_empty(),
		"starts_lowercase": first_is_letter and first == first.to_lower() and first != first.to_upper(),
		"starts_with_digit": first != "" and first >= "0" and first <= "9",
		"starts_with_symbol": first != "" and not first_is_letter and not (first >= "0" and first <= "9"),
		"has_digits": digits > 0,
		"has_emoji": emoji > 0,
		"has_math": math > 0,
		"has_special": special > 0,
		"has_spaces": spaces > 0,
		"all_caps": letters > 1 and lowercase == 0 and uppercase > 1,
		"no_letters": letters == 0 and not player_name.is_empty(),
		"is_short": player_name.length() > 0 and player_name.length() <= 2,
		"is_long": player_name.length() >= 14,
		"non_latin": non_latin > 0,
		"is_tidy": false,
	}
	traits["is_tidy"] = (
		not bool(traits["is_empty"])
		and not bool(traits["starts_lowercase"])
		and not bool(traits["has_digits"])
		and not bool(traits["has_emoji"])
		and not bool(traits["has_math"])
		and not bool(traits["has_special"])
		and not bool(traits["all_caps"])
		and not bool(traits["is_short"])
		and not bool(traits["is_long"])
	)
	return traits

## Short list of what Milka noticed, used by the input hint line.
static func notes(raw_name: String) -> PackedStringArray:
	var traits: Dictionary = analyze(raw_name)
	var list: PackedStringArray = []
	if bool(traits["starts_lowercase"]):
		list.append("starts small")
	if bool(traits["has_digits"]):
		list.append("has numbers")
	if bool(traits["has_emoji"]):
		list.append("has emoji")
	if bool(traits["has_math"]):
		list.append("has math signs")
	if bool(traits["has_special"]):
		list.append("has special symbols")
	if bool(traits["all_caps"]):
		list.append("shouts in capitals")
	if bool(traits["is_long"]):
		list.append("is quite long")
	if bool(traits["is_short"]):
		list.append("is very short")
	return list

## Human readable validation message, empty when the name may be used.
static func validation_error(raw_name: String) -> String:
	var player_name: String = raw_name.strip_edges()
	if player_name.length() < MIN_LENGTH:
		return "Milka is waiting for at least one character."
	if player_name.length() > MAX_LENGTH:
		return "That is longer than %d characters. Milka cannot breathe."
	return ""

static func _is_letter(code: int) -> bool:
	if code >= 65 and code <= 90:
		return true
	if code >= 97 and code <= 122:
		return true
	if code >= 0xC0 and code <= 0x24F:
		return true
	if code >= 0x370 and code <= 0x1CFF:
		return true
	if code >= 0x4E00 and code <= 0x9FFF:
		return true
	return false

static func _is_math_unicode(code: int) -> bool:
	if code >= 0x2200 and code <= 0x22FF:
		return true
	if code == 0xB1 or code == 0xD7 or code == 0xF7:
		return true
	if code == 0x221E or code == 0x2260 or code == 0x2264 or code == 0x2265:
		return true
	return false

static func _is_emoji(code: int) -> bool:
	if code >= 0x1F000 and code <= 0x1FAFF:
		return true
	if code >= 0x2600 and code <= 0x27BF:
		return true
	if code == 0x200D or (code >= 0xFE00 and code <= 0xFE0F):
		return true
	if code >= 0x2190 and code <= 0x21FF:
		return true
	return false
