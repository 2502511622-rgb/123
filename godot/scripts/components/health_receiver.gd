class_name YinHealthReceiver
extends Node
signal damaged(amount: int, kind: String)
signal depleted
var record: Dictionary
var source: Object
var property: String = "hp"
func bind_record(data: Dictionary) -> void:
	record = data
	source = null
	property = "hp"
func bind_source(data: Object, key: String) -> void:
	source = data
	property = key
func value() -> int:
	return int(source.get(property)) if source != null else int(record.get(property, 0))
func apply(amount: int, kind: String) -> int:
	if amount <= 0 or value() <= 0: return 0
	var previous: int = value()
	var next: int = maxi(0, previous - amount)
	if source != null: source.set(property, next)
	else: record[property] = next
	damaged.emit(previous - next, kind)
	if next == 0: depleted.emit()
	return previous - next
