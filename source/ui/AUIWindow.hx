package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import mobile.TouchUtil;

/** Draggable editor window. Add child controls with addContent(). */
class AUIWindow extends FlxSpriteGroup
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
        super(x, y);
        this.title = title;
        windowWidth = width;
        windowHeight = height;
        background = new FlxSprite().makeGraphic(width, height, 0xFF172332);
        add(background);
        titleBar = new FlxSprite(0, 0).makeGraphic(width, 30, 0xFF26394D);
        add(titleBar);
        titleText = new FlxText(10, 8, width - 20, title, 12);
        titleText.setFormat(null, 12, FlxColor.WHITE, LEFT);
        add(titleText);
    }

    public function addContent(item:flixel.FlxSprite):Void add(item);

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (!draggable) return;
        if (FlxG.mouse.justPressed && (FlxG.mouse.overlaps(titleBar) || TouchUtil.justPressedOn(titleBar)))
        {
            dragging = true;
            dragOffsetX = FlxG.mouse.x - x;
            dragOffsetY = FlxG.mouse.y - y;
        }
        if (FlxG.mouse.justReleased) dragging = false;
        if (dragging)
        {
            x = FlxG.mouse.x - dragOffsetX;
            y = FlxG.mouse.y - dragOffsetY;
        }
    }
}
