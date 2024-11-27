extends Node

# TODO replace with offline data time
var last_updated_time: float = Time.get_unix_time_from_system() - 100000

# Used for distinguishing different collection types
enum Structures { Base_Map, Building, Room }
const Base_Map: int = 0
const Building: int = 1
const Room: int = 2

# Offline data used to store map data
# TODO loading and saving file
var offline_data: Dictionary

const BASE_MAP_COLLECTION: String = 'Base_Map'
const BUILDINGS_COLLECTION: String = 'Buildings'
const ROOMS_COLLECTION: String = 'Rooms'
const WAYPOINTS_COLLECTION: String = 'Waypoints'

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
	query_structure_data('Base_Map', Structures.Base_Map)

# Query the data for a structure recursively depending on last collection updated times
func query_structure_data(collection_path: String, structure_type: Structures) -> void:
	var sub_collection_path: String
	print('Starting querying: ' + collection_path)
	
	# Run for each document in collection
	for structure_document: FirestoreDocument in await Firebase.Firestore.list(collection_path):
		sub_collection_path = collection_path + "/" + structure_document.doc_name + '/'
		# Add reference to Waypoints collection
		structure_document.document[WAYPOINTS_COLLECTION] = {}
		print(structure_document)
		
		# Save data and run for specific sub collection
		match structure_type:
			Structures.Base_Map:
				# Add reference to Buildings collection
				structure_document.document[BUILDINGS_COLLECTION] = {}
				# Save to Base_Map document id
				offline_data[structure_document.doc_name] = structure_document.document
				
				# Run for Waypoints collection
				if  int(structure_document.document['waypoints_updated_time']['integerValue']) > last_updated_time:
					# Run for each Waypoint document in collection
					for waypoint_document: FirestoreDocument in await Firebase.Firestore.list(sub_collection_path + WAYPOINTS_COLLECTION):
						# Save to Base_Map document id -> Waypoints collection -> Waypoint document id
						offline_data[structure_document.doc_name][WAYPOINTS_COLLECTION][waypoint_document.doc_name] = waypoint_document.document
				
				# Run for Buildings collection if updated
				if int(structure_document.document['buildings_updated_time']['integerValue']) > last_updated_time:
					await query_structure_data(sub_collection_path + BUILDINGS_COLLECTION, Structures.Building)
			Structures.Building:
				# Add reference to Rooms collection
				structure_document.document[ROOMS_COLLECTION] = {}
				# Save to Base_Map document id -> Buildings collection -> Building document id
				offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION][structure_document.doc_name] = structure_document.document
				
				# Run for Waypoints collection
				if int(structure_document.document['waypoints_updated_time']['integerValue']) > last_updated_time:
					# Run for each Waypoint document in collection
					for waypoint_document: FirestoreDocument in await Firebase.Firestore.list(sub_collection_path + WAYPOINTS_COLLECTION):
						# Save to Base_Map document id -> Buildings collection -> Building document id -> Waypoints collection -> Waypoint document id
						offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION][structure_document.doc_name][WAYPOINTS_COLLECTION][waypoint_document.doc_name] = waypoint_document.document
				
				# Run for Rooms collection if updated
				if int(structure_document.document['rooms_updated_time']['integerValue']) > last_updated_time:
					await query_structure_data(sub_collection_path + ROOMS_COLLECTION, Structures.Room)
			Structures.Room:
				# Save to Base_Map document id -> Buildings collection -> Building document id -> Rooms collection -> Room document id
				offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION][collection_path.split('/')[3]][ROOMS_COLLECTION][structure_document.doc_name] = structure_document.document
				
				# Run for Waypoints collection
				if int(structure_document.document['waypoints_updated_time']['integerValue']) > last_updated_time:
					# Run for each Waypoint document in collection
					for waypoint_document: FirestoreDocument in await Firebase.Firestore.list(sub_collection_path + WAYPOINTS_COLLECTION):
						# Save to Base_Map document id -> Buildings collection -> Building document id -> Rooms collection -> Room document id -> Waypoints collection -> Waypoint document id
						offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION][collection_path.split('/')[3]][ROOMS_COLLECTION][structure_document.doc_name][WAYPOINTS_COLLECTION][waypoint_document.doc_name] = waypoint_document.document
	
	# TODO if needed make this concurrent for speedup
	if structure_type == Structures.Base_Map:
		print(JSON.stringify(offline_data, "\t"))
