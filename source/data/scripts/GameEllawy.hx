package data.scripts;

#if ELLAWY_ALLOWED
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxState;
import haxe.ds.StringMap;

import data.scripts.EllawyUtils;

class GameEllawy
{
    private static var initialized:Bool = false;
    private static var scripts:StringMap<GameEllawyScript> = new StringMap<GameEllawyScript>();
    private static var globals:StringMap<Dynamic> = new StringMap<Dynamic>();
    private static var callbacks:StringMap<Array<Dynamic->Void>> = new StringMap<Array<Dynamic->Void>>();

    //public var ellawy:State = null;
    public var scriptName:String = '';

    public function new(scriptName:String)
    {
        set('buildTarget', EllawyUtils.getBuildTarget());
    }

    /**
     * Initializes the Ellawy runtime.
     */
    public static function init():Void
    {
        if (initialized)
            return;

        initialized = true;

        registerDefaultGlobals();

        trace("[Ellawy] Runtime initialized.");
    }

    /**
     * Makes sure the runtime has been initialized.
     */
    private static function ensureInitialized():Void
    {
        if (!initialized)
            init();
    }

    /**
     * Registers basic game globals available to scripts.
     */
    private static function registerDefaultGlobals():Void
    {
        globals.set("game", FlxG);
        globals.set("width", FlxG.width);
        globals.set("height", FlxG.height);
        globals.set("framerate", FlxG.drawFramerate);
    }

    /**
     * Loads an Ellawy source string.
     *
     * The actual Ellawy interpreter can be connected here without changing
     * the rest of the game integration.
     */
    public static function load(name:String, source:String):Bool
    {
        ensureInitialized();

        if (name == null || StringTools.trim(name).length == 0)
            return false;

        if (source == null)
            source = "";

        name = EllawyUtils.sanitizeIdentifier(name);
        source = EllawyUtils.removeBOM(source);

        if (name.length == 0)
            return false;

        var script:GameEllawyScript = new GameEllawyScript(name, source);
        scripts.set(name, script);

        return true;
    }

    /**
     * Loads an Ellawy file from disk.
     */
    #if sys
    public static function loadFile(path:String, ?name:String):Bool
    {
        ensureInitialized();

        if (!EllawyUtils.isEllawyFile(path))
        {
            trace("[Ellawy] Not an .ellawy file: " + path);
            return false;
        }

        var source:Null<String> = EllawyUtils.readFile(path);

        if (source == null)
            return false;

        if (name == null || name.length == 0)
            name = EllawyUtils.fileNameWithoutExtension(path);

        return load(name, source);
    }
    #else
    public static function loadFile(path:String, ?name:String):Bool
    {
        return false;
    }
    #end

    /**
     * Unloads one script.
     */
    public static function unload(name:String):Void
    {
        ensureInitialized();

        if (name == null)
            return;

        scripts.remove(EllawyUtils.sanitizeIdentifier(name));
    }

    /**
     * Removes every loaded script.
     */
    public static function unloadAll():Void
    {
        scripts = new StringMap<GameEllawyScript>();
    }

    /**
     * Returns true when a script is loaded.
     */
    public static function exists(name:String):Bool
    {
        ensureInitialized();

        if (name == null)
            return false;

        return scripts.exists(EllawyUtils.sanitizeIdentifier(name));
    }

    /**
     * Gets a loaded script.
     */
    public static function getScript(name:String):GameEllawyScript
    {
        ensureInitialized();

        if (name == null)
            return null;

        return scripts.get(EllawyUtils.sanitizeIdentifier(name));
    }

    /**
     * Calls a function/event registered by a script.
     *
     * Returns the value supplied by the script callback.
     */
    public static function call(name:String, event:String, args:Array<Dynamic> = null):Dynamic
    {
        ensureInitialized();

        var script:GameEllawyScript = getScript(name);

        if (script == null)
            return null;

        return script.call(event, args);
    }

    /**
     * Broadcasts an event to every loaded Ellawy script.
     */
    public static function broadcast(event:String, args:Array<Dynamic> = null):Void
    {
        ensureInitialized();

        for (script in scripts)
        {
            if (script != null)
                script.call(event, args);
        }

        dispatchCallback(event, args == null ? null : args.length > 0 ? args[0] : null);
    }

    /**
     * Registers a native callback.
     *
     * This is useful for connecting game states/classes to Ellawy.
     */
    public static function on(event:String, callback:Dynamic->Void):Void
    {
        ensureInitialized();

        if (event == null || callback == null)
            return;

        var list:Array<Dynamic->Void> = callbacks.get(event);

        if (list == null)
        {
            list = [];
            callbacks.set(event, list);
        }

        if (list.indexOf(callback) == -1)
            list.push(callback);
    }

    /**
     * Removes a native callback.
     */
    public static function off(event:String, callback:Dynamic->Void):Void
    {
        if (event == null || callback == null)
            return;

        var list:Array<Dynamic->Void> = callbacks.get(event);

        if (list == null)
            return;

        list.remove(callback);

        if (list.length == 0)
            callbacks.remove(event);
    }

    /**
     * Dispatches a native event.
     */
    public static function dispatch(event:String, value:Dynamic = null):Void
    {
        ensureInitialized();

        if (event == null)
            return;

        for (script in scripts)
        {
            if (script != null)
                script.call(event, value == null ? [] : [value]);
        }

        dispatchCallback(event, value);
    }

    private static function dispatchCallback(event:String, value:Dynamic):Void
    {
        var list:Array<Dynamic->Void> = callbacks.get(event);

        if (list == null)
            return;

        // Copy so callbacks may safely unregister themselves.
        var copy:Array<Dynamic->Void> = list.copy();

        for (callback in copy)
        {
            try
            {
                callback(value);
            }
            catch (e:Dynamic)
            {
                trace("[Ellawy] Native callback error: " + e);
            }
        }
    }

    /**
     * Sets a global variable.
     */
    public static function set(name:String, value:Dynamic):Void
    {
        ensureInitialized();

        if (name == null)
            return;

        globals.set(name, value);

        for (script in scripts)
        {
            if (script != null)
                script.set(name, value);
        }
    }

    /**
     * Gets a global variable.
     */
    public static function get(name:String, defaultValue:Dynamic = null):Dynamic
    {
        ensureInitialized();

        if (name == null)
            return defaultValue;

        return globals.exists(name) ? globals.get(name) : defaultValue;
    }

    /**
     * Returns the currently loaded script names.
     */
    public static function getLoadedScripts():Array<String>
    {
        ensureInitialized();

        var result:Array<String> = [];

        for (name in scripts.keys())
            result.push(name);

        return result;
    }

    /**
     * Called when the current game state changes.
     */
    public static function stateCreate(state:FlxState):Void
    {
        ensureInitialized();

        set("state", state);
        dispatch("onStateCreate", state);
    }

    /**
     * Called when the current state is destroyed.
     */
    public static function stateDestroy(state:FlxState):Void
    {
        dispatch("onStateDestroy", state);

        if (get("state") == state)
            set("state", null);
    }

    /**
     * Called every frame.
     */
    public static function update(elapsed:Float):Void
    {
        ensureInitialized();

        set("elapsed", elapsed);
        dispatch("onUpdate", elapsed);
    }

    /**
     * Called when the game starts.
     */
    public static function gameStart():Void
    {
        ensureInitialized();
        dispatch("onStartGame");
    }

    /**
     * Called when the game ends.
     */
    public static function gameEnd():Void
    {
        dispatch("onEndGame");
    }

    /**
     * Clears the complete runtime.
     */
    public static function clear():Void
    {
        scripts = new StringMap<GameEllawyScript>();
        globals = new StringMap<Dynamic>();
        callbacks = new StringMap<Array<Dynamic->Void>>();
        initialized = false;
    }
}

/**
 * Internal representation of one Ellawy script.
 *
 * This class provides the runtime boundary. If the Ellawy Haxelib API
 * changes, only this class needs to be adapted.
 */
class GameEllawyScript
{
    public final name:String;
    public final source:String;

    private var handlers:StringMap<Dynamic->Array<Dynamic>->Dynamic>;
    private var variables:StringMap<Dynamic>;

    public function new(name:String, source:String)
    {
        this.name = name;
        this.source = source;

        handlers = new StringMap<Dynamic->Array<Dynamic>->Dynamic>();
        variables = new StringMap<Dynamic>();

        parseSource();
    }

    /**
     * Basic event discovery.
     *
     * This recognizes common Ellawy-style function declarations while
     * keeping the runtime safe when a script contains syntax that belongs
     * to a newer Ellawy parser.
     */
    private function parseSource():Void
    {
        var lines:Array<String> = source.split("\n");

        for (line in lines)
        {
            var cleaned:String = EllawyUtils.stripComment(line);
            cleaned = StringTools.trim(cleaned);

            if (cleaned.length == 0)
                continue;

            // function onStartGame(...)
            if (StringTools.startsWith(cleaned, "function "))
            {
                var rest:String = StringTools.trim(cleaned.substr(9));
                var open:Int = rest.indexOf("(");

                if (open > 0)
                {
                    var eventName:String = StringTools.trim(rest.substr(0, open));

                    if (eventName.length > 0)
                        registerPlaceholder(eventName);
                }
            }
        }
    }

    private function registerPlaceholder(eventName:String):Void
    {
        if (!handlers.exists(eventName))
        {
            handlers.set(eventName, function(args:Array<Dynamic>):Dynamic
            {
                return null;
            });
        }
    }

    /**
     * Registers a native Haxe function for an Ellawy event.
     *
     * This is useful until the full Ellawy evaluator is connected.
     */
    public function bind(eventName:String, callback:Dynamic->Array<Dynamic>->Dynamic):Void
    {
        if (eventName == null || callback == null)
            return;

        handlers.set(eventName, callback);
    }

    /**
     * Calls a script event.
     */
    public function call(eventName:String, args:Array<Dynamic> = null):Dynamic
    {
        if (eventName == null)
            return null;

        var callback:Dynamic->Array<Dynamic>->Dynamic = handlers.get(eventName);

        if (callback == null)
            return null;

        if (args == null)
            args = [];

        try
        {
            return callback(this, args);
        }
        catch (e:Dynamic)
        {
            trace('[Ellawy] Error in "' + name + '" event "' + eventName + '": ' + e);
        }

        return null;
    }

    public function set(name:String, value:Dynamic):Void
    {
        if (name == null)
            return;

        variables.set(name, value);
    }

    public function get(name:String, defaultValue:Dynamic = null):Dynamic
    {
        if (name == null || !variables.exists(name))
            return defaultValue;

        return variables.get(name);
    }
}
#end
