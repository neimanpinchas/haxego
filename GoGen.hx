import haxe.macro.Type;
import haxe.macro.JSGenApi;
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.TypedExprTools;
import haxe.Timer;
using StringTools;
class GoGen {
    static var imports = [];
    var api : JSGenApi;
    var buf : StringBuf;
    static var hxClasses:Array<String> = [];

    public function new(api)
    {
        this.api = api;
        buf = new StringBuf();
        api.setTypeAccessor(getType);
    }

    inline function getType(t : Type)
    {
        return switch(t) {
            case TInst(c, _): getPath(c.get());
            case TEnum(e, _): getPath(e.get());
            default: throw "assert";
        };
    }

    inline function print(str)
    {
        buf.add(str);
    }

    inline function newline()
    {
        print("\n");
        var x = indentCount;
        while(x-- > 0)	print("\t");
    }

    inline function genExpr(e)
    {
        var expr:haxe.macro.TypedExpr = e;
        var exprString = new GoPrinter().printExpr(expr);
        print(exprString.replace("super(", "super.init("));
        return exprString;
    }

    inline function field(p : String)
    {
    	return GoPrinter.handleKeywords(p);
    }

    static var classCount = 0;

    inline function genPathHacks(t:Type)
    {
        switch( t ) {
            case TInst(c, _):
                var c = c.get();
                if(!c.isExtern)classCount++;
                getPath(c);
            case TEnum(r, _):
                var e = r.get();
                getPath(e);
            default:
        }
    }

    function getPath(t : BaseType)
    {
		var fullPath = t.name;

		if(t.pack.length > 0)
		{
		    var dotPath = t.pack.join(".") + "." + t.name;
		    fullPath =  t.pack.join("_") + "_" + t.name;

		    if(!GoPrinter.pathHack.exists(dotPath))
		        GoPrinter.pathHack.set(dotPath, fullPath);
		}

	//	if(t.module != t.name)   //TODO(av) see what this does with sub classes in packages
		{
		    var modulePath = t.module + "." + t.name;
		    if(!GoPrinter.pathHack.exists(modulePath))
		        GoPrinter.pathHack.set(modulePath, t.name);
		}
        return t.module + "_" + t.name;
        return fullPath;
    }

    inline function checkFieldName(c : ClassType, f : ClassField)
    {
        if(GoPrinter.keywords.indexOf(f.name) > -1)
            Context.error("The *class* field named " + f.name + " is not allowed in Lua", c.pos);
    }

    var props:Array<String> = [];
    inline function addPropToClass(name:String)
    {
    	props.push(name);
    }

    function genClassField(c : ClassType, p : String, f : ClassField)
    {
        checkFieldName(c, f);
        var field = field(f.name);
        var e = f.expr();
        return if(e == null)
        {
        	#if verbose print('--var $field;'); #end
        	switch( f.kind ) // getter
        	{
        		case FVar(AccCall, _), FVar(AccResolve, _):
            	addPropToClass('get_$field');
            	case FVar(AccNever, _): // ignored
            	default:
        	}
        	switch( f.kind ) // setter
        	{
        		case FVar(_, AccCall):
        		addPropToClass('set_$field');
        		case FVar(_, AccNever): // ignored
            	default:
        	}
            "";
        }
        else switch( f.kind )
        {
            case FMethod(_):
                print('func $p:$field');
                GoPrinter.printFunctionHead = false;
                var exp=genExpr(e);
                newline();
                exp;
            default:
                print('var $field = ');
                var exp=genExpr(e);
                print(";");
                newline();
                exp;
        }
        newline();
    }

    function genStaticField(c : ClassType, p : String, f : ClassField)
    {
        var classes = classCount > 1;

        checkFieldName(c, f);

        var stat = classCount > 1 ? 'static' : "";

        var field = field(f.name);
        var e = f.expr();
        return if(e == null)
        {
        	#if verbose print('--$stat var $field;'); //TODO(av) initialisation of static vars if needed
            #end
            newline();
            "\n";
        }
        else switch( f.kind ) {
            case FMethod(_):
                print('func (${p.charAt(0)} ${p}) $field {');
                GoPrinter.printFunctionHead = false;
                var exp=genExpr(e);
                newline();
                exp;
            default:
                print('${p}.$field = ');
                var exp=genExpr(e);
                print(";");
                newline();
                exp;
        }

    }

    var ignorance = [
        // top classes:
        // TODO: move up and uncomment when implemented
        "String_String",
        //"Array_Array",
        "HxOverrides_HxOverrides",
        "Std_Std",
        "js_Boot_Boot",   
        "haxe_Log_Log",
        "StringTools_StringTools",
        "EReg_EReg",
        "Enum_Enum",
        "Type_Type",
        "haxe_Json_Json",

        // temporal fix:

        "Class_Class",
        "Date_Date",
        "DateTools_DateTools",
        "EnumValue_EnumValue",
        "IntIterator_IntIterator",
        "Lambda_Lambda",
        "List_List",
        "Map_Map",
        "Math_Math",
        "Reflect_Reflect",
        "StdTypes_StdTypes",
        //"StringBuf", "StringBuf_StringBuf",
        "UInt_UInt",
        "Xml_Xml",
        "haxe_ds_IntMap_IntMap",
        "Map_IMap", 
    ];

    function genClass(c : ClassType)
    {
        
        for(meta in c.meta.get())
        {
            if(meta.name == ":require")
            {
                for(param in meta.params)
                {
                    switch(param.expr){
                        case EConst(CString(s)):
                            if(Lambda.indexOf(imports, s) == - 1)
                                imports.push(s);
                        default:
                    }
                }
            } else
            if(meta.name == ":remove")
            {
                return;
            }
        }

        api.setCurrentClass(c);
        var p = getPath(c);
        var package_name=p;
        var __name__ = p;
        p = p.replace(".","_");
        if(!hxClasses.contains(p)) hxClasses.push(p);

        GoPrinter.currentPath = p + ".";

        var cm=new ClassMaker();
        cm.classname=p;

        if(classCount > 0)
        {
            var psup:String = null;
            GoPrinter.superClass = null;
            if(c.superClass != null)
            {
                psup = getPath(c.superClass.t.get());
                #if verbose print('-- class $p extends $psup'); #end
                GoPrinter.superClass = psup;
            } else {
            	#if verbose print('-- class $p'); #end
            }       

            if(ignorance.contains(p))
            {
            	if(!hxClasses.contains(p)) hxClasses.push(p);
            	#if verbose print(' ignored --\n'); #end
                return ;
            }

            if(c.isInterface)
            {
            	#if verbose print('-- abstract class $p'); #end
            }
            else
                {

                    cm.save("bin/vendor/");
                    print('\ntype $p struct {
                        
                    }');
                    if(psup != null)
                    print('\n___inherit($p, ${psup});'.replace(".", "_"));
                    else
                    print('\n___inherit($p, Object);'.replace(".", "_"));

                    print('\n$p.__name__ = "$__name__";');

                    print('\n$p.__index = $p;');
                    //todo first caps
                    var filetext='
                        package $p

                        type $p struct {

                        }

                        var  X__name__ = "$p"
                        var X__index = $p
                    ';
                    
                }

            if(c.interfaces.length > 0)
            {
                var me = this;
                var inter = c.interfaces.map(function(i) return me.getPath(i.t.get())).join(",");
                #if verbose print(' -- implements $inter'); #end
            }

            openBlock();
        }

        if(c.constructor != null)
        {
            trace("generating constructor");
            cm.methods.push({
                name:"new",
                definition:new GoPrinter().printExpr(c.constructor.get().expr())
            });
            newline();
            print('func (${p.charAt(0)} $p) new(){');
            GoPrinter.insideConstructor = p;
            GoPrinter.printFunctionHead = false;
            genExpr(c.constructor.get().expr());
            GoPrinter.insideConstructor = null;
            newline();
            
        }

        for(f in c.statics.get()){
            //new GoPrinter().printExpr(c.constructor.get().expr());
            trace("generating static");
            var sf=genStaticField(c, p, f);
            cm.static_methods.push({
                name:f.name,
                definition:sf
            });
        }

        for(f in c.fields.get())
        {
            trace("generating field");
            switch( f.kind ) {
                case FVar(r, _):
                    if(r == AccResolve) continue;
                default:
            }
            var cf=genClassField(c, p, f);
            switch (f.kind){
                case FMethod(_):
                    cm.methods.push({
                        name:f.name,
                        definition:cf
                    });
                default:
                    trace(f.name,f.type);
                    cm.vars.push({
                        name:f.name,
                        type:gettype(f.type)
                    });
    
        
            }
        }
        cm.save("bin/vendor/");

        if(!c.isInterface)
        {
        	print('\n$p.__props__ = {');
    	    if(props.length > 0) {
    	    	var last = props.pop();
    	    	for(i in props) print('"$i",');
    	    	print('"$last"');
    	    }
    	    print('};');
    	    props = [];
    	}

        if(classCount > 1)
        {
            closeBlock();
        }
    }

    static var firstEnum = true;

    function genEnum(e : EnumType)
    {
        if(firstEnum)
        {
            generateBaseEnum();
            firstEnum = false;
        }

        var p = getPath(e).replace(".", "_");

        #if verbose print('--class $p extends Enum {'); #end
        print('\n$p = {}');
        newline();
        #if verbose print('--$p(t, i, [p]):super(t, i, p);'); #end
        newline();
        for(c in e.constructs.keys())
        {
            var c = e.constructs.get(c);
            var f = field(c.name);
            print('$p.$f = ');
            switch( c.type ) {
                case TFun(args, _):
                    var sargs = args.map(function(a) return a.name).join(",");
                    print('func($sargs) {return $p.new("${c.name}", ${c.index}, {[0]=$sargs}); end');
                default:
                    print('{[0]=${api.quoteString(c.name)}, [1]=${c.index}};');
            }
            newline();
        }

        #if verbose print("--} --<-- huh?"); #end
        newline();
    }


    function genStaticValue(c : ClassType, cf : ClassField)
    {
        var p = getPath(c);
        var f = field(cf.name);
        print('$p$f = ');
        genExpr(cf.expr());
        newline();
    }

    function genType(t : Type)
    {
        switch( t ) {
            case TInst(c, _):
                var c = c.get();
                if(! c.isExtern) genClass(c);
            case TEnum(r, _):
                var e = r.get();
                if(! e.isExtern) genEnum(e);
            default:
        }
    }

    function generateBaseEnum()
    {
        /*print("abstract class Enum {
        	String tag;
        	int index;
        	List params;
        	Enum(this.tag, this.index, [this.params]);
        	toString()=>params == null ? tag : tag + '(' + params.join(',') + ')';
        	}");	// String toString() { return haxe.Boot.enum_to_string(this); }*/
        print("
            Enum = {}
            Enum_Enum = Enum
        ");
        newline();
    }

    public function generate()
    {
    	var now = Timer.stamp();

        for(t in api.types)
            genPathHacks(t);

        var starter = "";

        if(api.main != null)// && classCount > 1)
        {
            print("");

            genExpr(api.main);
            print(";");
            newline();

            starter = buf.toString();
            buf = new StringBuf();
        }

        for(t in api.types)
            genType(t);

        var importsBuf = new StringBuf();//currently only works within a single output file. Needs to be handled module by module

        for(mpt in imports)
            importsBuf.add("require \"" + mpt + "\"\n");

        var boot;

		var pos = Context.getPosInfos((macro null).pos);
		var dir = haxe.io.Path.directory(pos.file);
		var path = haxe.io.Path.addTrailingSlash(dir);

        boot = new StringBuf();

        #if !bootless

        boot.add( "___hxClasses = {" );
        for (i in hxClasses) {
            boot .add( ''+ i +' = ' + i + "," );
        }
        boot .add( "}" );

		// boot .add( "" + sys.io.File.getContent('$path/boot/boot.lua') );
		// boot .add( "\n" + sys.io.File.getContent('$path/boot/tostring.lua') );
		// if(hxClasses.contains("Std_Std")) boot .add( "\n" + sys.io.File.getContent('$path/boot/std.lua') );
		// /*if(hxClasses.has("Math_Math"))*/ boot .add( "\n" + sys.io.File.getContent('$path/boot/math.lua') );
        // if(hxClasses.contains("Type_Type")) boot .add( "\n" + sys.io.File.getContent('$path/boot/type.lua') );
		// boot .add( "\n" + sys.io.File.getContent('$path/boot/string.lua') );
        // if(hxClasses.contains("StringTools_StringTools")) boot .add( "\n" + sys.io.File.getContent('$path/boot/stringtools.lua') );
		// boot .add( "\n" + sys.io.File.getContent('$path/boot/object.lua') );
		// if(hxClasses.contains("Map_Map") || hxClasses.contains("haxe_ds_IntMap_IntMap")) boot .add( "\n" + sys.io.File.getContent('$path/boot/map.lua') );
		// boot .add( "\n" + sys.io.File.getContent('$path/boot/date.lua') );
		// if(hxClasses.contains("List_List")) boot .add( "\n" + sys.io.File.getContent('$path/boot/list.lua') );
        // /*if(hxClasses.has("haxe_Json_Json"))*/ boot .add( "\n" + sys.io.File.getContent('$path/boot/json.lua') );
		// boot .add( "\n" + sys.io.File.getContent('$path/boot/extern.lua') ); // TODO remove from *release*
		// boot .add( "\n" + sys.io.File.getContent('$path/boot/ereg.lua') ); // TODO remove from *release*

        #end

		var r;

        r = ~/\n[ \t]{0,}--[^\n]+/g;
        var bootStr = r.replace(boot.toString(), "");
        r = ~/--[^\n]+/g;
        bootStr = r.replace(bootStr, "");
        bootStr = bootStr.replace("\n\n", "\n");

        var result = new StringBuf();

        result.add(importsBuf.toString());
        // #if !bootless result.add(sys.io.File.getContent('$path/boot/preboot.lua')); #end
        result.add("\npackage main\n");
        result.add(buf.toString());
        result.add("\nend\n");
        result.add(bootStr);
        result.add("\nexec()\n");
        result.add(starter);

        sys.io.File.saveContent(api.outputFile, result.toString());        	

        trace('Go generated in ${Std.int((Timer.stamp() - now)*1000)}ms');
    }

    static var indentCount : Int = 0;

    inline function openBlock()
    {
        #if verbose newline(); print("--{"); #end
        indentCount ++;
        newline();
    }

    inline function closeBlock()
    {
        indentCount --;
        #if verbose newline(); print("--}"); #end
        newline();
        newline();
    }
    public static function init_go() {
        Compiler.setCustomJSGenerator(function(api) new GoGen(api).generate());
    }


    public static function gettype(t:haxe.macro.Type):String{
        var haxetype= t.getParameters()[0];
        trace(haxetype);
        return switch (Std.string(haxetype)) {
            case "Int":
                "int";
            case "Bool":
                "bool";
            case "Array":
            "[]interface{}";
            case "Void":
                "";
            case _:
                 Std.string(haxetype).replace(".","_");
        }
    }
}