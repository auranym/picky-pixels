@tool
## A PickyPixels project contains all information and necessary data
## for rendering a set of sprites, textures, models, etc. within a single
## viewport. The common link between these assets is that they share a color
## palette (and optional effects). Thus, the purpose of a PickyPixels project
## is to set up and easily use a strict color palette.
class_name PickyPixelsProjectData
extends Resource


const TRANSPARENT_ID = "TRANSPARENT"
const TRANSPARENT_RAMP = [Color(0.0, 0.0, 0.0, 0.0)]
const UNUSABLE_RAMP = []

## Name of the project. Must be unique.
@export var name: String:
	get: return name
	set(val):
		name = val
		emit_changed()

## Color palette for this project.
@export var palette: Array[Color]:
	get: return palette
	set(val):
		palette = val
		_color_index_map = {}
		_unusable_ramp_indices_set = {}
		for i in palette.size():
			_color_index_map[_color_to_str(palette[i])] = i
			_unusable_ramp_indices_set[256 * palette[i].b8 + palette[i].g8] = true
		emit_changed()

## Ramps that should be processed in decoding colors.
@export var ramps: Array[Array] = []:
	get: return ramps
	set(val):
		ramps = val
		_ramp_index_map = {}
		for i in ramps.size():
			_ramp_index_map[_ramp_to_str(ramps[i])] = i
		emit_changed()

# Used for O(1) lookup time.
# Maps a value to its respective index.
var _color_index_map := {}
var _ramp_index_map := {}
# Set of integers (0-255) that are not usable as ramps due to
# the green value being in the color palette.
var _unusable_ramp_indices_set := {}


func _color_to_str(color) -> String:
	if color.a8 != 255:
		return TRANSPARENT_ID
	
	return "{r},{g},{b}".format({
		"r": color.r8,
		"g": color.g8,
		"b": color.b8
	})


func _ramp_to_str(ramp) -> String:
	var strings = []
	var all_transparent = true
	for color in ramp:
		var str = _color_to_str(color)
		if all_transparent and str != TRANSPARENT_ID:
			all_transparent = false
		strings.push_back(str)
	if all_transparent:
		return TRANSPARENT_ID
	return ";".join(strings)


## Returns the index of the passed color within the palette array,
## or -1 if the color does not exist in the palette.
func get_color_index(color) -> int:
	var str = _color_to_str(color)
	if _color_index_map.has(str):
		return _color_index_map[str]
	else:
		return -1


func has_color(color) -> bool:
	return _color_index_map.has(_color_to_str(color))


## Returns true if this project has all colors in input array
func has_colors(colors) -> bool:
	for color in colors:
		if not has_color(color):
			return false
	return true


## Returns the index of the passed ramp, or -1 if the ramp does not exist
## in the ramps array.
func get_ramp_index(ramp) -> int:
	var str = _ramp_to_str(ramp)
	if _ramp_index_map.has(str):
		return _ramp_index_map[str]
	else:
		return -1


func has_ramp(ramp) -> bool:
	return _ramp_index_map.has(_ramp_to_str(ramp))


## Returns true if this project has all ramps in input array
func has_ramps(ramps) -> bool:
	return num_missing_ramps(ramps) == 0


func is_ramp_transparent(ramp) -> bool:
	return _ramp_to_str(ramp) == TRANSPARENT_ID


## Compares this project's ramps with the parameter ramps. For every ramp
## that the project does not have, 1 is added to an accumlator (which starts
## at 0). That is, the return value is 0 if all ramps in parameter are in
## project, and more than 0 if there is one or more missing ramp.
func num_missing_ramps(ramps) -> int:
	return ramps.reduce(
		func(num_missing, ramp): return num_missing + (0 if has_ramp(ramp) else 1),
		0
	)


## Returns the number of unavailable ramps are currently stored within
## ramps array
func num_unavailable_ramps() -> int:
	return ramps.count(UNUSABLE_RAMP)


## Adds the ramp to the ramps array and returns the index at which the 
## ramp was added.
func add_ramp(ramp) -> int:
	var ramp_index = ramps.size()
	# Skip over indices that cannot be used due to the color palette
	while _unusable_ramp_indices_set.has(ramp_index):
		ramps.push_back(UNUSABLE_RAMP)
		ramp_index = ramps.size()
	ramps.push_back(ramp)
	_ramp_index_map[_ramp_to_str(ramp)] = ramp_index
	return ramp_index
