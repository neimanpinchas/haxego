package boot

func add(i *int, front bool) int {
	var tmp = *i + 1
	if front {
		return tmp
	}
	*i = *i + 1
	return *i
}
