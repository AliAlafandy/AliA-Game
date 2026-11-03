package flixel.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import mobile.TouchUtil;

/** Numeric slider with configurable range and step. */
class AUISlider extends FlxSpriteGroup
{
    public var track:FlxSprite;
    public var fill:FlxSprite;
    public var knob:FlxSprite;
    public var caption:FlxText;
    public var min:Float;
    public var max:Float;
    public var step:Float;
    public var value(default, set):Float = 0;
    public var onChange:Float->Void;
    private var sliderWidth:Int;
    private var dragging:Bool = false;

    public function new(x:Float, y:Float, width:Int, min:Float, max:Float, initialValue:Float = 0, step:Float = 1, ?callback:Float->Void)
    {
        super(x, y);
        sliderWidth = width;
        this.min = min;
        this.max = max <= min ? min + 1 : max;
        this.step = step <= 0 ? 1 : step;
        onChange = callback;
        caption = new FlxText(0, 0, width, "", 11);
        caption.setFormat(null, 11, FlxColor.WHITE, LEFT);
        add(caption);
        track = new FlxSprite(0, 24).makeGraphic(width, 6, 0xFF34475A);
        add(track);
        fill = new FlxSprite(0, 24).makeGraphic(width, 6, 0xFF35A6D8);
        add(fill);
        knob = new FlxSprite(0, 18).makeGraphic(14, 18, 0xFFEAF4FA);
        add(knob);
        value = initialValue;
        refresh();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (FlxG.mouse.justPressed && (FlxG.mouse.overlaps(track) || FlxG.mouse.overlaps(knob)
            || TouchUtil.justPressedOn(track) || TouchUtil.justPressedOn(knob)))
            dragging = true;
        if (FlxG.mouse.justReleased) dragging = false;
        if (dragging)
        {
            var ratio = (FlxG.mouse.x - x) / sliderWidth;
            value = min + (max - min) * Math.max(0, Math.min(1, ratio));
        }
    }

    private function set_value(next:Float):Float
    {
        var clamped = Math.max(min, Math.min(max, next));
        value = min + Math.round((clamped - min) / step) * step;
        value = Math.max(min, Math.min(max, value));
        refresh();
        if (onChange != null) onChange(value);
        return value;
    }

    private function refresh():Void
    {
        if (caption != null) caption.text = Std.string(Math.round(value * 100) / 100);
        if (fill != null && knob != null)
        {
            var ratio = (value - min) / (max - min);
            fill.scale.x = ratio;
            fill.updateHitbox();
            knob.x = ratio * sliderWidth - knob.width * 0.5;
        }
    }
}
