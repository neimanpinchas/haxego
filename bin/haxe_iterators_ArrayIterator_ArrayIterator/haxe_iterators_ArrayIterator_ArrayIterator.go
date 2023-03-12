package haxe_iterators_ArrayIterator_ArrayIterator
        struct haxe_iterators_ArrayIterator_ArrayIterator {
            array []interface{}
current int
        }
        
        func (self *haxe_iterators_ArrayIterator_ArrayIterator) newfunc(array TInst)
		self.current = 0;
		self.array = array
	}
func (self *haxe_iterators_ArrayIterator_ArrayIterator) hasNext()
		return self.current < self.array.length;
	}
func (self *haxe_iterators_ArrayIterator_ArrayIterator) next()
		return self.array[++self.current];
	}