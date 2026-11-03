package flixel.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import mobile.TouchUtil;

/** Boolean toggle with mouse and touch support. */
class AUICheckbox extends FlxSpriteGroup
{
    public var box:FlxSprite;
    public var mark:FlxText;
    public var caption:FlxText;
    public var checked(default, set):Bool = false;
    public var onChange:Bool->Void;

    public function new(x:Float, y:Float, label:String, initialValue:Bool = false, ?callback:Bool->Void)
    {
        super(x, y);
        checked = initialValue;
        onChange = callback;
        box = new FlxSprite().makeGraphic(20, 20, 0xFF172332);
        add(box);
        mark = new FlxText(2, 1, 17, 18, "", 15);
        mark.setFormat(null, 15, FlxColor.LIME, CENTER);
        add(mark);
        caption = new FlxText(28, 3, 220, label, 12);
        caption.setFormat(null, 12, FlxColor.WHITE, LEFT);
        add(caption);
        refresh();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        var mousePressed = FlxG.mouse.justPressed && (FlxG.mouse.overlaps(box) || FlxG.mouse.overlaps(caption));
        var touchPressed = TouchUtil.justPressedOn(box) || TouchUtil.justPressedOn(caption);
        if (mousePressed || touchPressed)
            checked = !checked;
    }

    private function set_checked(next:Bool):Bool
    {
        checked = next;
        refresh();
        if (onChange != null) onChange(checked);
        return checked;
    }

    private function refresh():Void
    {
        if (mark != null) mark.text = checked ? "✓" : "";
        if (box != null) box.color = checked ? 0xFF286B55 : 0xFF172332;
    }
}
