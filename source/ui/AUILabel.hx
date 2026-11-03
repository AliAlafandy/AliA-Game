package ui;

import flixel.text.FlxText;
import flixel.util.FlxColor;

/** Consistent label typography for editor panels and inspectors. */
class AUILabel extends FlxText
{
    public function new(x:Float, y:Float, width:Float, text:String, size:Int = 12, color:FlxColor = FlxColor.WHITE)
    {
        super(x, y, width, text, size);
        setFormat(null, size, color, LEFT);
    }
}
