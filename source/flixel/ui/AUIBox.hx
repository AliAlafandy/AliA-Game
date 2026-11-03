package flixel.ui;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/** Reusable panel for the AliA-Game Flixel editor UI. */
class AUIBox extends FlxGroup
{
    public var panel:FlxSprite;
    public var heading:FlxText;

    public function new(x:Float, y:Float, width:Int, height:Int, title:String = "")
    {
        super();
        panel = new FlxSprite(x, y).makeGraphic(width, height, 0xFF1B2736);
        add(panel);
        if (title != "")
        {
            var bar = new FlxSprite(x, y).makeGraphic(width, 30, 0xFF263449);
            add(bar);
            heading = new FlxText(x + 10, y + 8, width - 20, title, 12);
            heading.setFormat(null, 12, FlxColor.CYAN, LEFT);
            add(heading);
        }
    }

    public function addContent(item:flixel.FlxBasic):Void add(item);
}
