class_name NodeUtilities


static func get_all_children(in_node: Node, arr: Array[Node] = []) -> Array[Node]:
	# from https://forum.godotengine.org/t/how-to-get-all-children-from-a-node/18587/2
	arr.push_back(in_node)
	for child in in_node.get_children():
		arr = get_all_children(child, arr)
	return arr
