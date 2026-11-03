package flixel.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import mobile.TouchUtil;

/** Draggable editor window. Add child controls with addContent(). */
class AUIWindow extends FlxGroup
{
    public var background:FlxSprite;
    public var titleBar:FlxSprite;
    public var titleText:FlxText;
    public var title:String;
    public var windowWidth:Int;
    public var windowHeight:Int;
    public var draggable:Bool = true;
    private var dragging:Bool = false;
    private var dragOffsetX:Float = 0;
    private var dragOffsetY:Float = 0;

    public function new(x:Float, y:Float, width:Int, height:Int, title:String = "Window")
    {
        super();
        this.title = title;
        windowWidth = width;
        windowHeight = height;
        background = new FlxSprite(x, y).makeGraphic(width, height, 0xFF172332);
        add(background);
        titleBar = new FlxSprite(x, y).makeGraphic(width, 30, 0xFF26394D);
        add(titleBar);
        titleText = new FlxText(x + 10, y + 8, width - 20, title, 12);
        titleText.setFormat(null, 12, FlxColor.WHITE, LEFT);
        add(titleText);
    }

    public function addContent(item:flixel.FlxBasic):Void add(item);

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (!draggable) return;
        if (FlxG.mouse.justPressed && (FlxG.mouse.overlaps(titleBar) || TouchUtil.justPressedOn(titleBar)))
        {
            dragging = true;
            dragOffsetX = FlxG.mouse.x - background.x;
            dragOffsetY = FlxG.mouse.y - background.y;
        }
        if (FlxG.mouse.justReleased) dragging = false;
        if (dragging)
        {
            var nextX = FlxG.mouse.x - dragOffsetX;
            var nextY = FlxG.mouse.y - dragOffsetY;
            var dx = nextX - background.x;
            var dy = nextY - background.y;
            background.x += dx; background.y += dy;
            titleBar.x += dx; titleBar.y += dy;
            titleText.x += dx; titleText.y += dy;
        }
    }
}
