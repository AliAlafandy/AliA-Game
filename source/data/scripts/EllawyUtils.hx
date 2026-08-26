package data.scripts;

#if ELLAWY_ALLOWED
import haxe.Json;
import haxe.ds.StringMap;
import haxe.io.Path;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class EllawyUtils
{
    public static inline var EXTENSION:String = ".ellawy";

    /**
     * Returns true when a path points to an Ellawy file.
     */
    public static function isEllawyFile(path:String):Bool
    {
        if (path == null)
            return false;

        return Path.extension(path).toLowerCase() == "ellawy";
    }

    /**
     * Normalizes an Ellawy path.
     */
    public static function normalizePath(path:String):String
    {
        if (path == null)
            return "";

        var result:String = StringTools.replace(path, "\\", "/");

        while (StringTools.startsWith(result, "./"))
            result = result.substr(2);

        return result;
    }

    /**
     * Safely reads an Ellawy source file.
     */
    #if sys
    public static function readFile(path:String):Null<String>
    {
        if (path == null || path.length == 0)
            return null;

        var normalized:String = normalizePath(path);

        try
        {
            if (!FileSystem.exists(normalized))
                return null;

            if (FileSystem.isDirectory(normalized))
                return null;

            return File.getContent(normalized);
        }
        catch (e:Dynamic)
        {
            trace('[Ellawy] Failed to read file: ' + normalized);
            trace(e);
        }

        return null;
    }
    #else
    public static function readFile(path:String):Null<String>
    {
        return null;
    }
    #end

    /**
     * Writes an Ellawy source file.
     */
    #if sys
    public static function writeFile(path:String, content:String):Bool
    {
        if (path == null || path.length == 0)
            return false;

        if (content == null)
            content = "";

        var normalized:String = normalizePath(path);

        try
        {
            var directory:String = Path.directory(normalized);

            if (directory != null && directory.length > 0 && !FileSystem.exists(directory))
                FileSystem.createDirectory(directory);

            File.saveContent(normalized, content);
            return true;
        }
        catch (e:Dynamic)
        {
            trace('[Ellawy] Failed to write file: ' + normalized);
            trace(e);
        }

        return false;
    }
    #else
    public static function writeFile(path:String, content:String):Bool
    {
        return false;
    }
    #end

    /**
     * Loads a JSON object from a string.
     *
     * Ellawy can use JSON-like data, so this helper is useful for
     * configuration/data sections.
     */
    public static function parseJson(source:String):Dynamic
    {
        if (source == null)
            return null;

        var text:String = StringTools.trim(source);

        if (text.length == 0)
            return null;

        try
        {
            return Json.parse(text);
        }
        catch (e:Dynamic)
        {
            trace('[Ellawy] JSON parse error: ' + e);
            return null;
        }
    }

    /**
     * Converts a dynamic value into a Bool.
     */
    public static function toBool(value:Dynamic, defaultValue:Bool = false):Bool
    {
        if (value == null)
            return defaultValue;

        if (Std.isOfType(value, Bool))
            return cast value;

        if (Std.isOfType(value, String))
        {
            var text:String = StringTools.trim(Std.string(value)).toLowerCase();

            switch (text)
            {
                case "true", "1", "yes", "on":
                    return true;

                case "false", "0", "no", "off":
                    return false;
            }
        }

        if (Std.isOfType(value, Float) || Std.isOfType(value, Int))
            return Std.parseFloat(Std.string(value)) != 0;

        return defaultValue;
    }

    /**
     * Converts a dynamic value into a Float.
     */
    public static function toFloat(value:Dynamic, defaultValue:Float = 0):Float
    {
        if (value == null)
            return defaultValue;

        var result:Float = Std.parseFloat(Std.string(value));

        if (Math.isNaN(result))
            return defaultValue;

        return result;
    }

    /**
     * Converts a dynamic value into an Int.
     */
    public static function toInt(value:Dynamic, defaultValue:Int = 0):Int
    {
        if (value == null)
            return defaultValue;

        var result:Float = Std.parseFloat(Std.string(value));

        if (Math.isNaN(result))
            return defaultValue;

        return Std.int(result);
    }

    /**
     * Converts a value into a String.
     */
    public static function toString(value:Dynamic, defaultValue:String = ""):String
    {
        if (value == null)
            return defaultValue;

        return Std.string(value);
    }

    /**
     * Gets a property from a Dynamic object safely.
     */
    public static function getProperty(object:Dynamic, property:String, defaultValue:Dynamic = null):Dynamic
    {
        if (object == null || property == null)
            return defaultValue;

        try
        {
            var value:Dynamic = Reflect.getProperty(object, property);

            return value == null ? defaultValue : value;
        }
        catch (e:Dynamic)
        {
            return defaultValue;
        }
    }

    /**
     * Sets a property on a Dynamic object safely.
     */
    public static function setProperty(object:Dynamic, property:String, value:Dynamic):Bool
    {
        if (object == null || property == null)
            return false;

        try
        {
            Reflect.setProperty(object, property, value);
            return true;
        }
        catch (e:Dynamic)
        {
            trace('[Ellawy] Failed to set property "' + property + '": ' + e);
        }

        return false;
    }

    /**
     * Calls a Dynamic function safely.
     */
    public static function call(object:Dynamic, functionName:String, args:Array<Dynamic> = null):Dynamic
    {
        if (object == null || functionName == null)
            return null;

        try
        {
            var fn:Dynamic = Reflect.getProperty(object, functionName);

            if (fn == null || !Reflect.isFunction(fn))
                return null;

            if (args == null)
                args = [];

            return Reflect.callMethod(object, fn, args);
        }
        catch (e:Dynamic)
        {
            trace('[Ellawy] Function call failed: ' + functionName);
            trace(e);
        }

        return null;
    }

    /**
     * Splits an argument list while preserving quoted strings.
     */
    public static function splitArguments(text:String):Array<String>
    {
        var result:Array<String> = [];

        if (text == null || StringTools.trim(text).length == 0)
            return result;

        var current:String = "";
        var quote:String = "";
        var escaped:Bool = false;

        for (i in 0...text.length)
        {
            var character:String = text.charAt(i);

            if (escaped)
            {
                current += character;
                escaped = false;
                continue;
            }

            if (character == "\\")
            {
                escaped = true;
                current += character;
                continue;
            }

            if (quote.length > 0)
            {
                current += character;

                if (character == quote)
                    quote = "";

                continue;
            }

            if (character == "\"" || character == "'")
            {
                quote = character;
                current += character;
                continue;
            }

            if (character == ",")
            {
                result.push(StringTools.trim(current));
                current = "";
                continue;
            }

            current += character;
        }

        if (current.length > 0 || text.charAt(text.length - 1) == ",")
            result.push(StringTools.trim(current));

        return result;
    }

    /**
     * Removes a UTF-8 BOM if one exists.
     */
    public static function removeBOM(text:String):String
    {
        if (text == null)
            return "";

        if (text.length > 0 && text.charCodeAt(0) == 0xFEFF)
            return text.substr(1);

        return text;
    }

    /**
     * Removes // comments from a source line.
     *
     * This is deliberately simple and does not remove // inside quotes.
     */
    public static function stripComment(line:String):String
    {
        if (line == null)
            return "";

        var quote:String = "";
        var escaped:Bool = false;

        for (i in 0...line.length)
        {
            var c:String = line.charAt(i);

            if (escaped)
            {
                escaped = false;
                continue;
            }

            if (c == "\\")
            {
                escaped = true;
                continue;
            }

            if (quote.length > 0)
            {
                if (c == quote)
                    quote = "";

                continue;
            }

            if (c == "\"" || c == "'")
            {
                quote = c;
                continue;
            }

            if (c == "/" && i + 1 < line.length && line.charAt(i + 1) == "/")
                return line.substr(0, i);
        }

        return line;
    }

    /**
     * Makes a safe identifier for script-side names.
     */
    public static function sanitizeIdentifier(value:String):String
    {
        if (value == null)
            return "";

        var result:String = "";

        for (i in 0...value.length)
        {
            var c:String = value.charAt(i);

            if (
                (c >= "a" && c <= "z") ||
                (c >= "A" && c <= "Z") ||
                (c >= "0" && c <= "9") ||
                c == "_"
            )
            {
                result += c;
            }
            else
            {
                result += "_";
            }
        }

        return result;
    }

    /**
     * Returns the filename without its extension.
     */
    public static function fileNameWithoutExtension(path:String):String
    {
        if (path == null)
            return "";

        var file:String = Path.withoutDirectory(normalizePath(path));
        return Path.withoutExtension(file);
    }

    /**
     * Converts an Array into a StringMap.
     *
     * Expected array format:
     *
     * [
     *     { key: "foo", value: 123 },
     *     { key: "bar", value: true }
     * ]
     */
    public static function arrayToMap(values:Array<Dynamic>):StringMap<Dynamic>
    {
        var map:StringMap<Dynamic> = new StringMap<Dynamic>();

        if (values == null)
            return map;

        for (item in values)
        {
            if (item == null)
                continue;

            var key:Dynamic = getProperty(item, "key", null);

            if (key == null)
                continue;

            map.set(Std.string(key), getProperty(item, "value", null));
        }

        return map;
    }
}
#end
