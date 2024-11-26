extends Node

func _ready() -> void:
	# Connect signals to methods
	var _error: int = Firebase.Auth.signup_succeeded.connect(on_signup_succeeded)
	_error = Firebase.Auth.login_failed.connect(on_login_failed)
	
	Firebase.Auth.login_anonymous()

# Run on successful sign in
func on_signup_succeeded(auth: Dictionary) -> void:
	print(auth)
	# Get the Base Map Document to work with
	var base_map_document: FirestoreDocument = (await Firebase.Firestore.list('Base_Map'))[0]
	print(base_map_document)
	var base_map_waypoints_collection: Array = await Firebase.Firestore.list('Base_Map/' + base_map_document.doc_name + "/Waypoints")
	print(base_map_waypoints_collection)
	
	

# Login unavailable, either authentication messed up or no internet.
func on_login_failed(error_code: String, message: String) -> void:
	print("error code: " + error_code)
	if error_code == "Connection error":
		# Handle no internet connection
		print("message: " + message)
	else:
		# Handle authentication error
		print("message: " + message)
	
