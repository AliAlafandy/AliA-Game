package flixel.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import mobile.TouchUtil;

/** Clickable/touchable editor button with its own background and caption. */
class AUIButton extends FlxSpriteGroup
{
    public var background:FlxSprite;
    public var caption:FlxText;
    public var onClick:Void->Void;
    public var enabled:Bool = true;
    private var hitArea:FlxSprite;

    public function new(x:Float, y:Float, width:Int, height:Int, text:String, ?callback:Void->Void)
    {
        super(x, y);
        onClick = callback;
        // Input hit testing uses screen-space bounds, not the group's local children.
        hitArea = new FlxSprite(x, y).makeGraphic(width, height, 0x00000000);
        hitArea.visible = false;
        background = new FlxSprite().makeGraphic(width, height, 0xFF30445B);
        add(background);
        caption = new FlxText(4, Std.int((height - 12) * 0.5), width - 8, text, 10);
        caption.setFormat(null, 10, FlxColor.WHITE, CENTER);
        add(caption);
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (!enabled || onClick == null) return;
        var pressed = (FlxG.mouse.justPressed && FlxG.mouse.overlaps(hitArea))
            || TouchUtil.justPressedOn(hitArea);
        if (pressed)
        {
            FlxG.sound.play(Paths.sound("scroll_sound"));
            onClick();
        }
    }

    public function setLabel(value:String):Void caption.text = value;

    public function setEnabled(value:Bool):Void
    {
        enabled = value;
        background.alpha = value ? 1 : 0.45;
        caption.alpha = background.alpha;
    }
}
