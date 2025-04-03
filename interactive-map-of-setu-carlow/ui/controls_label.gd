extends Label


func _ready() -> void:
	var os_name: String = OS.get_name()
	if os_name == "Android" or (os_name == "Web" and OS.has_feature("web_android")):
		visible = false
