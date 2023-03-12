
package main

type Main_Main struct {
                        
                    }
___inherit(Main_Main, Object);
Main_Main.__name__ = "Main_Main";
Main_Main.__index = Main_Main;
	func (M Main_Main) main {()  {
		unknown("Hello World", map[string]interface{}{ "fileName" : "Main.hx", "lineNumber" : 5, "className" : "Main", "methodName" : "main" })
	}
	
Main_Main.__props__ = {};


type haxe_iterators_ArrayIterator_ArrayIterator struct {
                        
                    }
___inherit(haxe_iterators_ArrayIterator_ArrayIterator, Object);
haxe_iterators_ArrayIterator_ArrayIterator.__name__ = "haxe.iterators.ArrayIterator_ArrayIterator";
haxe_iterators_ArrayIterator_ArrayIterator.__index = haxe_iterators_ArrayIterator_ArrayIterator;
	
	func (h haxe_iterators_ArrayIterator_ArrayIterator) new(){(array []interface{})  {
		self := setmetatable({ }, haxe_iterators_ArrayIterator_ArrayIterator)
		self.current = 0;
		self.array = array
		return self
	}
	func haxe_iterators_ArrayIterator_ArrayIterator:hasNext() bool {
		return self.current < self.array.length;
	}
	func haxe_iterators_ArrayIterator_ArrayIterator:next() haxe_iterators_ArrayIterator_T {
		return self.array[add(self.current,true)];
	}
	
haxe_iterators_ArrayIterator_ArrayIterator.__props__ = {};


end
___hxClasses = {Main_Main = Main_Main,Std_Std = Std_Std,haxe_iterators_ArrayIterator_ArrayIterator = haxe_iterators_ArrayIterator_ArrayIterator,}
exec()
Main_Main.main();
