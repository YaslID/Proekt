extends Node

func is_dictionary(value) -> bool:
	return typeof(value) == TYPE_DICTIONARY

func is_array(value) -> bool:
	return typeof(value) == TYPE_ARRAY

func is_string(value) -> bool:
	return typeof(value) == TYPE_STRING