extends RefCounted
# Read resources off-thread; scene-tree construction remains on the main thread.
static func warm(owner:Node,paths:Array)->Array:
	var resources:Array=[]
	for path in paths:
		if ResourceLoader.load_threaded_get_status(path)!=ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			ResourceLoader.load_threaded_request(path)
	for path in paths:
		while ResourceLoader.load_threaded_get_status(path)==ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await owner.get_tree().process_frame
		if ResourceLoader.load_threaded_get_status(path)==ResourceLoader.THREAD_LOAD_LOADED:
			resources.append(ResourceLoader.load_threaded_get(path))
	# Each opening owns its references, including when a previous opening is cancelled.
	return resources
