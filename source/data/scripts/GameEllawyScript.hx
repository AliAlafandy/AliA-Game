package data.scripts;

import ellawy.Ellawy;
import ellawy.Interpreter;
import ellawy.AST.Stmt;

class GameEllawyScript
{
    public final name:String;
    public final source:String;
    
    private var interpreter:Interpreter;
    private var ast:Array<Stmt>;
    private var handlers:Map<String, Dynamic>;

    public function new(name:String, source:String)
    {
        this.name = name;
        this.source = source;
        handlers = new Map();

        try 
        {
            ast = Ellawy.parse(source, name);
            interpreter = new Interpreter(name);
            interpreter.interpret(ast);
            extractFunctions();
        }
        catch (e:Dynamic)
        {
            trace('[Ellawy] Error loading script "$name": ' + e);
        }
    }

    private function extractFunctions():Void
    {
        for (key in interpreter.environment.keys()) {
            var val = interpreter.environment.get(key);
            if (Reflect.isFunction(val)) {
                handlers.set(key, val);
            }
        }
    }

    public function call(eventName:String, args:Array<Dynamic> = null):Dynamic
    {
        if (handlers.exists(eventName)) {
            var fn = handlers.get(eventName);
            if (args == null) args = [];
            
            try {
                return (cast fn : Array<Dynamic> -> Dynamic)(args);
            }
            catch (e:Dynamic) {
                trace('[Ellawy] Error calling "$eventName" in "$name": ' + e);
            }
        }
        return null;
    }

    public function set(varName:String, value:Dynamic):Void
    {
        if (interpreter != null) {
            interpreter.environment.set(varName, value);
        }
    }

    public function get(varName:String, defaultValue:Dynamic = null):Dynamic
    {
        if (interpreter != null && interpreter.environment.exists(varName)) {
            return interpreter.environment.get(varName);
        }
        return defaultValue;
    }
}
