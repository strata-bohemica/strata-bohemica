extends RefCounted
## Minimal test helper: ok(cond, message), then finish() -> exit code.
var failures: Array[String] = []
var count := 0
var quiet := false      # for guards run against a deliberately broken copy: failures are expected there

func ok(cond: bool, message: String) -> void:
	count += 1
	if not cond:
		failures.append(message)
		if not quiet:
			print("FAIL ", message)

func eq(a, b, message: String) -> void:
	ok(a == b, "%s (got %s, expected %s)" % [message, a, b])

func finish(tag: String) -> int:
	if failures.is_empty():
		print("PASS ", tag, " (", count, " assertions)")
		return 0
	print("FAILED ", tag, ": ", failures.size(), " of ", count)
	return 1
