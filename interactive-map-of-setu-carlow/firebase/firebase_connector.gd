extends Node
class_name FirebaseConnector

# Used for distinguishing different collection types
enum Structures { Base_Map, BuildingStruct, RoomStruct, WaypointStruct }
const Base_Map: int = 0
const BuildingStruct: int = 1
const RoomStruct: int = 2
const WaypointStruct: int = 3

const BASE_MAP_COLLECTION: String = 'Base_Map'
const BUILDINGS_COLLECTION: String = 'Buildings'
const ROOMS_COLLECTION: String = 'Rooms'
const WAYPOINTS_COLLECTION: String = 'Waypoints'

signal map_data_loaded()

func _ready() -> void:
	# Connect signals to methods
	var _error: int = Firebase.Auth.login_succeeded.connect(_on_FirebaseAuth_login_succeeded)
	_error = Firebase.Auth.signup_succeeded.connect(_on_FirebaseAuth_signup_succeeded)
	_error = Firebase.Auth.login_failed.connect(on_login_failed)
	_error = Firebase.Auth.auth_request.connect(on_auth_request)

	Globals.firebaseConnector = self
	Globals.load_offline_data()
	
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
	print("Error code: " + error_code)
	if error_code == "Connection error":
		# Handle no internet connection
		print("Message: " + message)
	else:
		# Handle authentication error
		print("Message: " + message)

# result_code either int or String
# result_content either String or something else
func on_auth_request(result_code: Variant, _result_content: Variant) -> void:
	if typeof(result_code) == TYPE_INT and result_code == 1:
		# Saved data has been authenticated
		print("OK Auth Request.")
		query_data()
	elif typeof(result_code) == TYPE_STRING and result_code == "Connection error":
		# No internet continue with loading
		map_data_loaded.emit()
	else:
		print("Error: " + result_code)
		Firebase.Auth.login_anonymous()

func delete_auth_file() -> void:
	print("Deleted auth file")
	Firebase.Auth.remove_auth()

# Query the map data down from Firebase to sync with local saved data.
func query_data() -> void:
	print("Start query data.")
	await query_structure_data('Base_Map', Structures.Base_Map, FirestoreDocument.new(), Globals.offline_data)
	Globals.save_offline_data()
	map_data_loaded.emit()

# Query the data for a structure recursively depending on last collection updated times
func query_structure_data(collection_path: String, structure_type: Structures, parent_document: FirestoreDocument, parent_structure_collection: Dictionary) -> void:
	print('Starting querying: ' + collection_path)
	var waypoints_updated: bool
	var child_structure_updated: bool
	var child_structure_updated_time_name: String
	var child_structure_collection_name: String
	var child_structure_type: Structures
	
	# Run for each document in collection
	print("First")
	for structure_document: FirestoreDocument in await Firebase.Firestore.list(collection_path):
		clean_structure_document_data(structure_document, structure_type)
		var sub_collection_path: String = collection_path + "/" + structure_document.doc_name + '/'
		print(structure_document)
		
		match structure_type:
			Structures.Base_Map:
				# Save to Base_Map document
				parent_document.document[structure_document.doc_name] = structure_document.document
				child_structure_updated_time_name = 'buildings_updated_time'
				child_structure_collection_name = BUILDINGS_COLLECTION
				child_structure_type = Structures.BuildingStruct
			Structures.BuildingStruct:
				# Save to Base_Map document id -> Buildings collection -> Building document id
				parent_document.document[BUILDINGS_COLLECTION][structure_document.doc_name] = structure_document.document
				child_structure_updated_time_name = 'rooms_updated_time'
				child_structure_collection_name = ROOMS_COLLECTION
				child_structure_type = Structures.RoomStruct
			Structures.RoomStruct:
				# Save to Base_Map document id -> Buildings collection -> Building document id -> Rooms collection -> Room document id
				parent_document.document[ROOMS_COLLECTION][structure_document.doc_name] = structure_document.document
		
		var new_collection: bool = parent_structure_collection.is_empty() or not parent_structure_collection.has(structure_document.doc_name)
		if new_collection:
			waypoints_updated = true
			child_structure_updated = true
		else:
			waypoints_updated = structure_document.document['waypoints_updated_time'] > parent_structure_collection[structure_document.doc_name]['waypoints_updated_time']
			# Check child structure
			if structure_type != Structures.RoomStruct:
				child_structure_updated = structure_document.document[child_structure_updated_time_name] > parent_structure_collection[structure_document.doc_name][child_structure_updated_time_name]
		
		# Run for Waypoints collection if updated
		if new_collection || waypoints_updated:
			structure_document.document[WAYPOINTS_COLLECTION] = {}
			# Run for each Waypoint document in collection
			print("Second")
			for waypoint_document: FirestoreDocument in await Firebase.Firestore.list(sub_collection_path + WAYPOINTS_COLLECTION):
				clean_structure_document_data(waypoint_document, Structures.WaypointStruct)
				# Save to Parent Structure -> Waypoints collection -> Waypoint document id
				structure_document.document[WAYPOINTS_COLLECTION][waypoint_document.doc_name] = waypoint_document.document
		else:
			structure_document.document[WAYPOINTS_COLLECTION] = parent_structure_collection[structure_document.doc_name][WAYPOINTS_COLLECTION]
		
		# Run for child structure collection if updated
		if new_collection || child_structure_updated:
			structure_document.document[child_structure_collection_name] = {}
			# If the collection is new then it dosen't exist in Globals data so pass null
			var collection_to_pass: Dictionary = {} if new_collection else parent_structure_collection[structure_document.doc_name][child_structure_collection_name]
			await query_structure_data(sub_collection_path + child_structure_collection_name, child_structure_type, structure_document, collection_to_pass)
		else:
			structure_document.document[child_structure_collection_name] = parent_structure_collection[structure_document.doc_name][child_structure_collection_name]
	
	if structure_type == Structures.Base_Map:
		Globals.offline_data = parent_document.document

# Clean up the data from Firebase for easier access
func clean_structure_document_data(structure_document: FirestoreDocument, structure_type: Structures) -> void:
	structure_document.document['longitude'] = structure_document.document['longitude']['doubleValue']
	structure_document.document['latitude'] = structure_document.document['latitude']['doubleValue']
	
	match structure_type:
			Structures.Base_Map:
				structure_document.document['waypoints_updated_time'] = str(structure_document.document['waypoints_updated_time']['integerValue']).to_int()
				structure_document.document['buildings_updated_time'] = str(structure_document.document['buildings_updated_time']['integerValue']).to_int()
				
			Structures.BuildingStruct:
				structure_document.document['name'] = structure_document.document['name']['stringValue']
				structure_document.document['description'] = structure_document.document['description']['stringValue']
				structure_document.document['building_letter'] = structure_document.document['building_letter']['stringValue']
				
				structure_document.document['waypoints_updated_time'] = str(structure_document.document['waypoints_updated_time']['integerValue']).to_int()
				structure_document.document['rooms_updated_time'] = str(structure_document.document['rooms_updated_time']['integerValue']).to_int()
				
			Structures.RoomStruct:
				structure_document.document['name'] = structure_document.document['name']['stringValue']
				structure_document.document['description'] = structure_document.document['description']['stringValue']
				structure_document.document['lecturers'] = structure_document.document['lecturers']['stringValue']
				
				structure_document.document['floor_number'] = str(structure_document.document['floor_number']['integerValue']).to_int()
				structure_document.document['parent_id'] = structure_document.document['parent_id']['stringValue']
				
				structure_document.document['waypoints_updated_time'] = str(structure_document.document['waypoints_updated_time']['integerValue']).to_int()
				
			Structures.WaypointStruct:
				structure_document.document['floor_number'] = str(structure_document.document['floor_number']['integerValue']).to_int()
				structure_document.document['feature_type'] = structure_document.document['feature_type']['stringValue']
				
				structure_document.document['parent_id'] = structure_document.document['parent_id']['stringValue']
				structure_document.document['parent_type'] = structure_document.document['parent_type']['stringValue']
				
				var waypoint_connections_ids_array: Array[String] = []
				var connection_array_dictionary: Dictionary = structure_document.document['waypoint_connections_ids']['arrayValue']
				if connection_array_dictionary.has('values'):
					for connection_id_dictionary: Dictionary in structure_document.document['waypoint_connections_ids']['arrayValue']['values']:
						waypoint_connections_ids_array.append(connection_id_dictionary.values()[0])
				structure_document.document['waypoint_connections_ids'] = waypoint_connections_ids_array

# Save the map data into the cloud
func save_map_data(id: String, fields: Array[String], parent_collection_path: String, global_structure_offline_data: Dictionary) -> void:
	var parent_collection: FirestoreCollection = Firebase.Firestore.collection(parent_collection_path)
	
	print("Third")
	var firestore_documents_list: Array = await Firebase.Firestore.list(parent_collection_path)
	var single_firestore_document_list: Array = firestore_documents_list.filter(func(x: FirestoreDocument) -> bool: return x.doc_name == id)
	
	if single_firestore_document_list.is_empty():
		# Create new Structure
		var _document: FirestoreDocument = await parent_collection.add(id, global_structure_offline_data)
	else:
		# Update Structure
		var structure_document: FirestoreDocument = single_firestore_document_list[0]
		for field_name: String in fields:
			if field_name == "":
				continue
			structure_document.add_or_update_field(field_name, global_structure_offline_data[field_name])
		var _document: FirestoreDocument = await parent_collection.update(structure_document)

# Update the structure updated time for the specific document
func update_structure_time(structure_document: FirestoreDocument, structure_updated_time_name: String, firestore_structure_collection_path: String, globals_offline_data_updated_time: int) -> void:
	structure_document.add_or_update_field(structure_updated_time_name, globals_offline_data_updated_time)
	var _document: FirestoreDocument = await Firebase.Firestore.collection(firestore_structure_collection_path).update(structure_document)

# Delete the specified document from the cloud
func delete_structure(path: String, id: String) -> void:
	var document_parent_collection: FirestoreCollection = Firebase.Firestore.collection('Base_Map/' + path)
	var document: FirestoreDocument = await document_parent_collection.get_doc(id)
	if document != null:
		var _was_deleted: bool = await document_parent_collection.delete(document)
