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
		
		var new_collection: bool = parent_structure_collection.is_empty() or structure_document.doc_name not in parent_structure_collection.keys()
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
	
	# TODO if needed make this concurrent for speedup, by removing await
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
				if 'values' in connection_array_dictionary.keys():
					for connection_id_dictionary: Dictionary in structure_document.document['waypoint_connections_ids']['arrayValue']['values']:
						waypoint_connections_ids_array.append(connection_id_dictionary.values()[0])
				structure_document.document['waypoint_connections_ids'] = waypoint_connections_ids_array

# Save the map data into the cloud
func save_map_data(id: String, fields: Array[String], parent_id: String) -> void:
	var _document: FirestoreDocument
	var structure_updated_time: int
	
	var updated_data: bool = false
	var base_map_id: String = Globals.offline_data.keys()[0]
	
	var base_map_collection : FirestoreCollection = Firebase.Firestore.collection('Base_Map')
	var base_map_document: FirestoreDocument = await base_map_collection.get_doc(base_map_id)
	if base_map_document == null:
		print("Retry")
		base_map_document = await base_map_collection.get_doc(base_map_id)
	
	var buildings_updated_time: int = Globals.offline_data[base_map_id]['buildings_updated_time']
	var waypoints_updated_time: int = Globals.offline_data[base_map_id]['waypoints_updated_time']
	
	# Save only base map
	if base_map_id == id:
		for field_name: String in fields:
			if field_name == "":
				continue
			base_map_document.add_or_update_field(field_name, Globals.offline_data[base_map_id][field_name])
		_document = await base_map_collection.update(base_map_document)
		return
	# Compare Waypoints last updated time
	if base_map_document.document['waypoints_updated_time']['integerValue'] != str(waypoints_updated_time) and (parent_id == "" or parent_id == base_map_id):
		var firestore_document_list: Array = await Firebase.Firestore.list('Base_Map/' + base_map_id + '/' + WAYPOINTS_COLLECTION)
		firestore_document_list = firestore_document_list.filter(func(x: FirestoreDocument) -> bool: return x.doc_name == id)
		
		# Create new Waypoint
		if firestore_document_list.is_empty():
			if parent_id != "" and base_map_id == parent_id:
				var new_structure_dictionary: Dictionary = Globals.offline_data[base_map_id][WAYPOINTS_COLLECTION][id]
				_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + WAYPOINTS_COLLECTION).add(id, new_structure_dictionary)
				updated_data = true
		else:
			var waypoint_document: FirestoreDocument = firestore_document_list[0]
			for field_name: String in fields:
				if field_name == "":
					continue
				if field_name == "waypoint_connections_ids":
					waypoint_document.add_or_update_field(field_name, Globals.offline_data[base_map_id][WAYPOINTS_COLLECTION][waypoint_document.doc_name]["waypoint_connections_ids"])
				else:
					waypoint_document.add_or_update_field(field_name, Globals.offline_data[base_map_id][WAYPOINTS_COLLECTION][waypoint_document.doc_name][field_name])
			_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + WAYPOINTS_COLLECTION).update(waypoint_document)
			updated_data = true
		
		if updated_data:
			# Update Waypoints time
			structure_updated_time = Globals.offline_data[base_map_id]['waypoints_updated_time']
			await update_structure_time(base_map_document, 'waypoints_updated_time', 'Base_Map', structure_updated_time)
			return
	# Compare Buildings last updated time
	if base_map_document.document['buildings_updated_time']['integerValue'] != str(buildings_updated_time):
		#TODO delete for loop
		for building_document: FirestoreDocument in await Firebase.Firestore.list('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION):
			var rooms_updated_time: int = Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name]['rooms_updated_time']
			waypoints_updated_time = Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name]['waypoints_updated_time']
			
			# Save only Building data
			if building_document.doc_name == id:
				for field_name: String in fields:
					if field_name == "":
						continue
					building_document.add_or_update_field(field_name, Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][field_name])
				_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION).update(building_document)
				
				# Update Buildings time
				structure_updated_time = Globals.offline_data[base_map_id]['buildings_updated_time']
				await update_structure_time(base_map_document, 'buildings_updated_time', 'Base_Map', structure_updated_time)
				return
			# Save Waypoints data
			if building_document.document['waypoints_updated_time']['integerValue'] != str(waypoints_updated_time) and (parent_id == "" or parent_id == building_document.doc_name):
				var firestore_document_list: Array = await Firebase.Firestore.list('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + WAYPOINTS_COLLECTION)
				firestore_document_list = firestore_document_list.filter(func(x: FirestoreDocument) -> bool: return x.doc_name == id)
				
				if firestore_document_list.is_empty():
					# Create new Waypoint
					if parent_id != "" and building_document.doc_name == parent_id:
						var new_structure_dictionary: Dictionary = Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][WAYPOINTS_COLLECTION][id]
						_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + WAYPOINTS_COLLECTION).add(id, new_structure_dictionary)
						updated_data = true
				else:
					var waypoint_document: FirestoreDocument = firestore_document_list[0]
					for field_name: String in fields:
						if field_name == "":
							continue
						if field_name == "waypoint_connections_ids":
							waypoint_document.add_or_update_field(field_name, Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][WAYPOINTS_COLLECTION][waypoint_document.doc_name]["waypoint_connections_ids"])
						else:
							waypoint_document.add_or_update_field(field_name, Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][WAYPOINTS_COLLECTION][waypoint_document.doc_name][field_name])
					_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + WAYPOINTS_COLLECTION).update(waypoint_document)
					updated_data = true
				
				if updated_data:
					# Update Waypoints time
					structure_updated_time = Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name]['waypoints_updated_time']
					await update_structure_time(building_document, 'waypoints_updated_time', 'Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION, structure_updated_time)
					
					# Update Buildings time
					structure_updated_time = Globals.offline_data[base_map_id]['buildings_updated_time']
					await update_structure_time(base_map_document, 'buildings_updated_time', 'Base_Map', structure_updated_time)
					return
			# Save Rooms data
			if building_document.document['rooms_updated_time']['integerValue'] != str(rooms_updated_time):
				#TODO delete for loop
				for room_document: FirestoreDocument in await Firebase.Firestore.list('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + ROOMS_COLLECTION):
					waypoints_updated_time = Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][ROOMS_COLLECTION][room_document.doc_name]['waypoints_updated_time']
					
					# Save only Room data
					if room_document.doc_name == id:
						for field_name: String in fields:
							if field_name == "":
								continue
							room_document.add_or_update_field(field_name, Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][ROOMS_COLLECTION][room_document.doc_name][field_name])
						_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + ROOMS_COLLECTION).update(room_document)
						
						# Update Rooms time
						structure_updated_time = Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name]['rooms_updated_time']
						await update_structure_time(building_document, 'rooms_updated_time', 'Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION, structure_updated_time)
						
						# Update Buildings time
						structure_updated_time = Globals.offline_data[base_map_id]['buildings_updated_time']
						await update_structure_time(base_map_document, 'buildings_updated_time', 'Base_Map', structure_updated_time)
						return
					# Save Waypoints data
					elif room_document.document['waypoints_updated_time']['integerValue'] != str(waypoints_updated_time) and (parent_id == "" or parent_id == room_document.doc_name):
						var firestore_document_list: Array = await Firebase.Firestore.list('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + ROOMS_COLLECTION + '/' + room_document.doc_name + '/' + WAYPOINTS_COLLECTION)
						firestore_document_list = firestore_document_list.filter(func(x: FirestoreDocument) -> bool: return x.doc_name == id)
						
						if firestore_document_list.is_empty():
							# Create new Waypoint
							if parent_id != "" and room_document.doc_name == parent_id:
								var new_structure_dictionary: Dictionary = Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][ROOMS_COLLECTION][room_document.doc_name][WAYPOINTS_COLLECTION][id]
								_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + ROOMS_COLLECTION + '/' + room_document.doc_name + '/' + WAYPOINTS_COLLECTION).add(id, new_structure_dictionary)
								updated_data = true
						else:
							var waypoint_document: FirestoreDocument = firestore_document_list[0]
							for field_name: String in fields:
								if field_name == "":
									continue
								if field_name == "waypoint_connections_ids":
									waypoint_document.add_or_update_field(field_name, Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][ROOMS_COLLECTION][room_document.doc_name][WAYPOINTS_COLLECTION][waypoint_document.doc_name]["waypoint_connections_ids"])
								else:
									waypoint_document.add_or_update_field(field_name, Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][ROOMS_COLLECTION][room_document.doc_name][WAYPOINTS_COLLECTION][waypoint_document.doc_name][field_name])
							_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + ROOMS_COLLECTION + '/' + room_document.doc_name + '/' + WAYPOINTS_COLLECTION).update(waypoint_document)
							updated_data = true
						
						if updated_data:
							# Update Waypoints time
							structure_updated_time = Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][ROOMS_COLLECTION][room_document.doc_name]['waypoints_updated_time']
							await update_structure_time(room_document, 'waypoints_updated_time', 'Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + ROOMS_COLLECTION, structure_updated_time)
							
							# Update Rooms time
							structure_updated_time = Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name]['rooms_updated_time']
							await update_structure_time(building_document, 'rooms_updated_time', 'Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION, structure_updated_time)
							
							# Update Buildings time
							structure_updated_time = Globals.offline_data[base_map_id]['buildings_updated_time']
							await update_structure_time(base_map_document, 'buildings_updated_time', 'Base_Map', structure_updated_time)
							return

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
