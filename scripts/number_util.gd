extends RefCounted

const _SUFFIXES: Array[String] = [
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"
]


static func format_mult(value: float) -> String:
	return "%.2fx" % value


static func format_percent(value: float) -> String:
	var pct := value * 100.0
	if absf(pct - roundf(pct)) < 0.05:
		return "%d%%" % int(roundf(pct))
	return "%.1f%%" % pct


static func format_duration(seconds: float) -> String:
	var total := maxi(0, int(roundf(seconds)))
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	var secs := total % 60
	if hours > 0:
		return "%dh %dm" % [hours, minutes]
	if minutes > 0:
		return "%dm %ds" % [minutes, secs]
	return "%ds" % secs


static func format_int(value: float) -> String:
	if not is_finite(value):
		return "0"
	return format(roundf(value))


static func format(value: float) -> String:
	if not is_finite(value):
		return "0"
	var sign := "-" if value < 0.0 else ""
	var magnitude := absf(value)
	if magnitude < 1000.0:
		return sign + _format_small(magnitude)
	if magnitude < 10000.0:
		return sign + _comma_int(magnitude)
	var suffix_index := 0
	var scaled := magnitude
	while scaled >= 1000.0 and suffix_index < _SUFFIXES.size() - 1:
		scaled /= 1000.0
		suffix_index += 1
	return sign + _format_scaled(scaled) + _SUFFIXES[suffix_index]


static func _format_small(n: float) -> String:
	if is_equal_approx(n, roundf(n)):
		return str(int(roundf(n)))
	return "%.2f" % n


static func _comma_int(n: float) -> String:
	var digits := str(int(roundf(n)))
	var result := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = digits[i] + result
		count += 1
	return result


static func _format_scaled(n: float) -> String:
	var text: String
	if n >= 100.0:
		text = "%.0f" % n
	elif n >= 10.0:
		text = "%.1f" % n
	else:
		text = "%.2f" % n
	if text.contains("."):
		text = text.rstrip("0").rstrip(".")
	return text
