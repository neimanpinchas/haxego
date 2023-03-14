import sys.FileSystem;
import sys.io.File;


class ClassMaker {
    public static function main(){

    }
    public function new() {
        
    }
    public var classname:String;
    public var methods=new Array<{name:String,definition:String}>();
    public var static_methods=new Array<{name:String,definition:String}>();
    public var vars=new Array<{name:String,type:String}>();
    public var static_vars= new Array<{name:String,definition:String}>();
    public function save(root:String){
        trace(vars);
        var fields=vars.map(x->x.name+" "+x.type).join("\n");
        var text='package $classname
        type $classname struct {
            $fields
        }
        
        '+static_methods.map(x->'func '+x.name+x.definition).join("\n")+
        methods.map(x->'func (self *$classname) '+x.name+x.definition).join("\n");
        FileSystem.createDirectory(root+"/"+classname);
        File.saveContent(root+"/"+classname+"/"+classname+".go",text);
        //trace(methods);
    }
}