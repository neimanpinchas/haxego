package haxe_iterators_ArrayIterator_ArrayIterator
        type haxe_iterators_ArrayIterator_ArrayIterator struct {
            array []interface{}
current int
        }
        
        func (self *haxe_iterators_ArrayIterator_ArrayIterator) newfunc(array []interface{})  {
		self.current = 0;
		self.array = array
	}
func (self *haxe_iterators_ArrayIterator_ArrayIterator) hasNext() bool {
		return self.current < self.array.length;
	}
func (self *haxe_iterators_ArrayIterator_ArrayIterator) next() haxe_iterators_ArrayIterator_T {
		return self.array[add(self.current,true)];
	}