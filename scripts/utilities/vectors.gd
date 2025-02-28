class_name Vectors


static func to_vector2(vec3: Vector3) -> Vector2:
	return Vector2(vec3.x, vec3.z)


static func to_vector3(vec2: Vector2, height: float = 0) -> Vector3:
	return Vector3(vec2.x, height, vec2.y)
