extends Node
class_name FirebaseConnector

# Used for distinguishing different collection types
enum Structures { Base_Map, BuildingStruct, RoomStruct }
const Base_Map: int = 0
const BuildingStruct: int = 1
const RoomStruct: int = 2

# New offline data from database
var new_offline_data: Dictionary

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
# result_content either String or 
@warning_ignore("untyped_declaration")
func on_auth_request(result_code, _result_content) -> void:
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
	await query_structure_data('Base_Map', Structures.Base_Map)
	Globals.save_offline_data()
	map_data_loaded.emit()

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
				# Add reference to collections
				var new_collection: bool = structure_document.doc_name not in Globals.offline_data.keys()
				if new_collection:
					structure_document.document[WAYPOINTS_COLLECTION] = {}
					structure_document.document[BUILDINGS_COLLECTION] = {}
				else:
					structure_document.document[WAYPOINTS_COLLECTION] = Globals.offline_data[structure_document.doc_name][WAYPOINTS_COLLECTION]
					structure_document.document[BUILDINGS_COLLECTION] = Globals.offline_data[structure_document.doc_name][BUILDINGS_COLLECTION]
				
				# Save to Base_Map document id
				new_offline_data[structure_document.doc_name] = structure_document.document
				
				# Run for Waypoints collection
				@warning_ignore("unsafe_call_argument")
				if new_collection || int(structure_document.document['waypoints_updated_time']['integerValue']) > int(Globals.offline_data[structure_document.doc_name]['waypoints_updated_time']['integerValue']):
					# Run for each Waypoint document in collection
					for waypoint_document: FirestoreDocument in await Firebase.Firestore.list(sub_collection_path + WAYPOINTS_COLLECTION):
						# Save to Base_Map document id -> Waypoints collection -> Waypoint document id
						new_offline_data[structure_document.doc_name][WAYPOINTS_COLLECTION][waypoint_document.doc_name] = waypoint_document.document
				
				# Run for Buildings collection if updated
				@warning_ignore("unsafe_call_argument")
				if new_collection || int(structure_document.document['buildings_updated_time']['integerValue']) > int(Globals.offline_data[structure_document.doc_name]['buildings_updated_time']['integerValue']):
					await query_structure_data(sub_collection_path + BUILDINGS_COLLECTION, Structures.BuildingStruct)
			Structures.BuildingStruct:
				# Add reference to collections
				@warning_ignore("unsafe_method_access")
				var new_collection: bool = collection_path.split('/')[1] not in Globals.offline_data.keys() or structure_document.doc_name not in Globals.offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION].keys()
				if new_collection:
					structure_document.document[WAYPOINTS_COLLECTION] = {}
					structure_document.document[ROOMS_COLLECTION] = {}
				else:
					structure_document.document[WAYPOINTS_COLLECTION] = Globals.offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION][structure_document.doc_name][WAYPOINTS_COLLECTION]
					structure_document.document[ROOMS_COLLECTION] = Globals.offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION][structure_document.doc_name][ROOMS_COLLECTION]
				
				# Save to Base_Map document id -> Buildings collection -> Building document id
				new_offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION][structure_document.doc_name] = structure_document.document
				
				# Run for Waypoints collection
				@warning_ignore("unsafe_call_argument")
				if new_collection || int(structure_document.document['waypoints_updated_time']['integerValue']) > int(Globals.offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION][structure_document.doc_name]['waypoints_updated_time']['integerValue']):
					# Run for each Waypoint document in collection
					for waypoint_document: FirestoreDocument in await Firebase.Firestore.list(sub_collection_path + WAYPOINTS_COLLECTION):
						# Save to Base_Map document id -> Buildings collection -> Building document id -> Waypoints collection -> Waypoint document id
						new_offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION][structure_document.doc_name][WAYPOINTS_COLLECTION][waypoint_document.doc_name] = waypoint_document.document
				
				# Run for Rooms collection if updated
				@warning_ignore("unsafe_call_argument")
				if new_collection || int(structure_document.document['rooms_updated_time']['integerValue']) > int(Globals.offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION][structure_document.doc_name]['rooms_updated_time']['integerValue']):
					await query_structure_data(sub_collection_path + ROOMS_COLLECTION, Structures.RoomStruct)
			Structures.RoomStruct:
				# Add reference to collection
				@warning_ignore("unsafe_method_access")
				var new_collection: bool = collection_path.split('/')[1] not in Globals.offline_data.keys() or collection_path.split('/')[3] not in Globals.offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION].keys() or structure_document.doc_name not in Globals.offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION][collection_path.split('/')[3]][ROOMS_COLLECTION].keys()
				if new_collection:
					structure_document.document[WAYPOINTS_COLLECTION] = {}
				else:
					structure_document.document[WAYPOINTS_COLLECTION] = Globals.offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION][collection_path.split('/')[3]][ROOMS_COLLECTION][structure_document.doc_name][WAYPOINTS_COLLECTION]
				
				# Save to Base_Map document id -> Buildings collection -> Building document id -> Rooms collection -> Room document id
				new_offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION][collection_path.split('/')[3]][ROOMS_COLLECTION][structure_document.doc_name] = structure_document.document
				
				# Run for Waypoints collection
				@warning_ignore("unsafe_call_argument")
				if new_collection || int(structure_document.document['waypoints_updated_time']['integerValue']) > int(Globals.offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION][collection_path.split('/')[3]][ROOMS_COLLECTION]['waypoints_updated_time']['integerValue']):
					# Run for each Waypoint document in collection
					for waypoint_document: FirestoreDocument in await Firebase.Firestore.list(sub_collection_path + WAYPOINTS_COLLECTION):
						# Save to Base_Map document id -> Buildings collection -> Building document id -> Rooms collection -> Room document id -> Waypoints collection -> Waypoint document id
						new_offline_data[collection_path.split('/')[1]][BUILDINGS_COLLECTION][collection_path.split('/')[3]][ROOMS_COLLECTION][structure_document.doc_name][WAYPOINTS_COLLECTION][waypoint_document.doc_name] = waypoint_document.document
	
	# TODO if needed make this concurrent for speedup, by removing await
	if structure_type == Structures.Base_Map:
		Globals.offline_data = new_offline_data

# Save the map data into the cloud
func save_map_data(id: String, fields: Array[String]) -> void:
	var base_map_id: String = Globals.offline_data.keys()[0]
	
	var base_map_collection : FirestoreCollection = Firebase.Firestore.collection('Base_Map')
	var base_map_document: FirestoreDocument = await base_map_collection.get_doc(base_map_id)
	
	var buildings_updated_time: String = Globals.offline_data[base_map_id]['buildings_updated_time']['integerValue']
	var waypoints_updated_time: String = Globals.offline_data[base_map_id]['waypoints_updated_time']['integerValue']
	
	# Save only base map
	if base_map_id == id:
		for field_name: String in fields:
			if field_name == "":
				continue
			@warning_ignore("unsafe_method_access")
			base_map_document.add_or_update_field(field_name, Globals.offline_data[base_map_id][field_name].values()[0])
		var _document: FirestoreDocument = await base_map_collection.update(base_map_document)
	# Compare Buildings last updated time
	elif base_map_document.document['buildings_updated_time']['integerValue'] != buildings_updated_time:
		@warning_ignore("unsafe_method_access")
		@warning_ignore("unsafe_call_argument")
		base_map_document.add_or_update_field('buildings_updated_time', int(Globals.offline_data[base_map_id]['buildings_updated_time'].values()[0]))
		var _document: FirestoreDocument = await base_map_collection.update(base_map_document)
		
		for building_document: FirestoreDocument in await Firebase.Firestore.list('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION):
			var rooms_updated_time: String = Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name]['rooms_updated_time']['integerValue']
			waypoints_updated_time = Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name]['waypoints_updated_time']['integerValue']
			
			# Save only Building data
			if building_document.doc_name == id:
				for field_name: String in fields:
					if field_name == "":
						continue
					@warning_ignore("unsafe_method_access")
					building_document.add_or_update_field(field_name, Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][field_name].values()[0])
				_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION).update(building_document)
				break
			# Save Rooms data
			elif building_document.document['rooms_updated_time']['integerValue'] != rooms_updated_time:
				@warning_ignore("unsafe_method_access")
				@warning_ignore("unsafe_call_argument")
				building_document.add_or_update_field('rooms_updated_time', int(Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name]['rooms_updated_time'].values()[0]))
				_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION).update(building_document)
				
				for room_document: FirestoreDocument in await Firebase.Firestore.list('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + ROOMS_COLLECTION):
					waypoints_updated_time = Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][ROOMS_COLLECTION][room_document.doc_name]['waypoints_updated_time']['integerValue']
					
					# Save only Room data
					if room_document.doc_name == id:
						for field_name: String in fields:
							if field_name == "":
								continue
								@warning_ignore("unsafe_method_access")
							room_document.add_or_update_field(field_name, Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][ROOMS_COLLECTION][room_document.doc_name][field_name].values()[0])
						_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + ROOMS_COLLECTION).update(room_document)
						break
					# Save Waypoints data
					elif room_document.document['waypoints_updated_time']['integerValue'] != waypoints_updated_time:
						@warning_ignore("unsafe_method_access")
						@warning_ignore("unsafe_call_argument")
						room_document.add_or_update_field('waypoints_updated_time', int(Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][ROOMS_COLLECTION][room_document.doc_name]['waypoints_updated_time'].values()[0]))
						_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + ROOMS_COLLECTION).update(room_document)
						
						for waypoint_document: FirestoreDocument in await Firebase.Firestore.list('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + ROOMS_COLLECTION + '/' + room_document.doc_name + '/' + WAYPOINTS_COLLECTION):
							if waypoint_document.doc_name == id:
								for field_name: String in fields:
									if field_name == "":
										continue
									if field_name == "waypoint_connections_ids":
										var connections_array: Array[String] = []
										for id_dictionaries: Dictionary in Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][ROOMS_COLLECTION][room_document.doc_name][WAYPOINTS_COLLECTION][waypoint_document.doc_name]["waypoint_connections_ids"]["arrayValue"]["values"]:
											connections_array.append(id_dictionaries.values()[0])
										waypoint_document.add_or_update_field(field_name, connections_array)
									else:
										@warning_ignore("unsafe_method_access")
										waypoint_document.add_or_update_field(field_name, Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][ROOMS_COLLECTION][room_document.doc_name][WAYPOINTS_COLLECTION][waypoint_document.doc_name][field_name].values()[0])
								_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + ROOMS_COLLECTION + '/' + room_document.doc_name + '/' + WAYPOINTS_COLLECTION).update(waypoint_document)
								break
						break
				break
			# Save Waypoints data
			elif building_document.document['waypoints_updated_time']['integerValue'] != waypoints_updated_time:
				@warning_ignore("unsafe_method_access")
				@warning_ignore("unsafe_call_argument")
				building_document.add_or_update_field('waypoints_updated_time', int(Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name]['waypoints_updated_time'].values()[0]))
				_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION).update(building_document)
				
				for waypoint_document: FirestoreDocument in await Firebase.Firestore.list('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + WAYPOINTS_COLLECTION):
					if waypoint_document.doc_name == id:
						for field_name: String in fields:
							if field_name == "":
								continue
							if field_name == "waypoint_connections_ids":
								var connections_array: Array[String] = []
								for id_dictionaries: Dictionary in Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][WAYPOINTS_COLLECTION][waypoint_document.doc_name]["waypoint_connections_ids"]["arrayValue"]["values"]:
									connections_array.append(id_dictionaries.values()[0])
								waypoint_document.add_or_update_field(field_name, connections_array)
							else:
								@warning_ignore("unsafe_method_access")
								waypoint_document.add_or_update_field(field_name, Globals.offline_data[base_map_id][BUILDINGS_COLLECTION][building_document.doc_name][WAYPOINTS_COLLECTION][waypoint_document.doc_name][field_name].values()[0])
						_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + BUILDINGS_COLLECTION + '/' + building_document.doc_name + '/' + WAYPOINTS_COLLECTION).update(waypoint_document)
						break
				break
	# Compare Waypoints last updated time
	elif base_map_document.document['waypoints_updated_time']['integerValue'] != waypoints_updated_time:
		@warning_ignore("unsafe_method_access")
		@warning_ignore("unsafe_call_argument")
		base_map_document.add_or_update_field('waypoints_updated_time', int(Globals.offline_data[base_map_id]['waypoints_updated_time'].values()[0]))
		var _document: FirestoreDocument = await base_map_collection.update(base_map_document)
		
		for waypoint_document: FirestoreDocument in await Firebase.Firestore.list('Base_Map/' + base_map_id + '/' + WAYPOINTS_COLLECTION):
			if waypoint_document.doc_name == id:
				for field_name: String in fields:
					if field_name == "":
						continue
					if field_name == "waypoint_connections_ids":
						var connections_array: Array[String] = []
						for id_dictionaries: Dictionary in Globals.offline_data[base_map_id][WAYPOINTS_COLLECTION][waypoint_document.doc_name]["waypoint_connections_ids"]["arrayValue"]["values"]:
							connections_array.append(id_dictionaries.values()[0])
						waypoint_document.add_or_update_field(field_name, connections_array)
					else:
						@warning_ignore("unsafe_method_access")
						waypoint_document.add_or_update_field(field_name, Globals.offline_data[base_map_id][WAYPOINTS_COLLECTION][waypoint_document.doc_name][field_name].values()[0])
				_document = await Firebase.Firestore.collection('Base_Map/' + base_map_id + '/' + WAYPOINTS_COLLECTION).update(waypoint_document)
				break
