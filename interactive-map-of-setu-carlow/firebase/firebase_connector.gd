extends Node

func _ready() -> void:
	# Connect signals to methods
	var _error: int = Firebase.Auth.login_succeeded.connect(_on_FirebaseAuth_login_succeeded)
	_error = Firebase.Auth.signup_succeeded.connect(_on_FirebaseAuth_signup_succeeded)
	_error = Firebase.Auth.login_failed.connect(on_login_failed)
	_error = Firebase.Auth.auth_request.connect(on_auth_request)
	
	# If auth file is saved, then use that
	var _success: bool =  Firebase.Auth.check_auth_file()

# Run on successful sign up
func _on_FirebaseAuth_signup_succeeded(auth: Dictionary) -> void:
	# Save auth for future use to stop clogging up connections to Firebase
	print("Auth saved.")
	var _success: bool =  Firebase.Auth.save_auth(auth)

# Run on successful login with
func _on_FirebaseAuth_login_succeeded(_auth: Dictionary) -> void:
	print("Logged in")

# Login unavailable, either authentication messed up or no internet.
func on_login_failed(error_code: String, message: String) -> void:
	print("error code: " + error_code)
	if error_code == "Connection error":
		# Handle no internet connection
		print("message: " + message)
	else:
		# Handle authentication error
		print("message: " + message)

# result_content either String or Dictionary
func on_auth_request(result_code: int, _result_content) -> void:
	if result_code == 1:
		# Saved data has been authenticated
		print("OK Auth Request.")
		query_data()
	else:
		Firebase.Auth.login_anonymous()

func delete_auth_file() -> void:
	print("Deleted auth file")
	Firebase.Auth.remove_auth()

# Query the map data down from Firebase to sync with local saved data.
func query_data() -> void:
	print("Start query data.")
	# Get the Base Map Document to work with
	var base_map_document: FirestoreDocument = (await Firebase.Firestore.list('Base_Map'))[0]
	print(base_map_document)
	var base_map_waypoints_collection: Array = await Firebase.Firestore.list('Base_Map/' + base_map_document.doc_name + "/Waypoints")
	print(base_map_waypoints_collection)
