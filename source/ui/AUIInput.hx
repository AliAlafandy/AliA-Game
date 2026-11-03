package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.events.KeyboardEvent;
import mobile.TouchUtil;

/** Focusable text input for editor tools. Keyboard input is captured only while focused. */
class AUIInput extends FlxSpriteGroup
{
    public var background:FlxSprite;
    public var caption:FlxText;
    public var value(default, set):String = "";
    public var placeholder:String;
    public var focused:Bool = false;
    public var onChange:String->Void;
    public var onSubmit:String->Void;

    public function new(x:Float, y:Float, width:Int, height:Int, placeholder:String = "", initialValue:String = "")
    {
        super(x, y);
        this.placeholder = placeholder;
        value = initialValue;
        background = new FlxSprite().makeGraphic(width, height, 0xFF172332);
        add(background);
        caption = new FlxText(8, 5, width - 16, "", 12);
        caption.setFormat(null, 12, FlxColor.WHITE, LEFT);
        add(caption);
        refresh();
        if (FlxG.stage != null) FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (FlxG.mouse.justPressed)
        {
            var hit = FlxG.mouse.overlaps(background) || TouchUtil.justPressedOn(background);
            setFocused(hit);
        }
    }

    private function onKeyDown(event:KeyboardEvent):Void
    {
        if (!focused) return;
        if (event.keyCode == 13)
        {
            if (onSubmit != null) onSubmit(value);
            setFocused(false);
            event.preventDefault();
            return;
        }
        if (event.keyCode == 8)
        {
            if (value.length > 0) value = value.substr(0, value.length - 1);
            event.preventDefault();
            return;
        }
        if (event.keyCode == 27)
        {
            setFocused(false);
            event.preventDefault();
            return;
        }
        if (event.charCode >= 32 && event.charCode <= 126)
        {
            value += String.fromCharCode(event.charCode);
            event.preventDefault();
        }
    }

    public function setFocused(state:Bool):Void
    {
        focused = state;
        background.color = focused ? 0xFF29445F : 0xFF172332;
    }

    private function set_value(next:String):String
    {
        value = next == null ? "" : next;
        refresh();
        if (onChange != null) onChange(value);
        return value;
    }

    private function refresh():Void
    {
        if (caption != null) caption.text = value.length == 0 && !focused ? placeholder : value + (focused ? "|" : "");
        if (caption != null && value.length == 0 && !focused) caption.color = 0xFF8795A5;
        else if (caption != null) caption.color = FlxColor.WHITE;
    }

    override public function destroy():Void
    {
        if (FlxG.stage != null) FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        super.destroy();
    }
}
