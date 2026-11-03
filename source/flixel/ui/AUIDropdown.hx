package flixel.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import mobile.TouchUtil;

/** Compact option selector. Clicking opens a list beneath the control. */
class AUIDropdown extends FlxSpriteGroup
{
    public var background:FlxSprite;
    public var caption:FlxText;
    public var options:Array<String>;
    public var selectedIndex(default, set):Int = 0;
    public var isOpen:Bool = false;
    public var onChange:Int->String->Void;
    private var optionRows:Array<FlxSprite> = [];
    private var optionLabels:Array<FlxText> = [];
    private var controlWidth:Int;
    private var rowHeight:Int = 27;

    public var selectedValue(get, never):String;
    private function get_selectedValue():String
        return options != null && selectedIndex >= 0 && selectedIndex < options.length ? options[selectedIndex] : "";

    public function new(x:Float, y:Float, width:Int, options:Array<String>, initialIndex:Int = 0, ?callback:Int->String->Void)
    {
        super(x, y);
        controlWidth = width;
        this.options = options == null ? [] : options.copy();
        onChange = callback;
        background = new FlxSprite().makeGraphic(width, 30, 0xFF172332);
        add(background);
        caption = new FlxText(8, 8, width - 16, "", 11);
        caption.setFormat(null, 11, FlxColor.WHITE, LEFT);
        add(caption);
        selectedIndex = initialIndex;
        refresh();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (!FlxG.mouse.justPressed && !TouchUtil.justPressed) return;
        if (FlxG.mouse.overlaps(background) || TouchUtil.justPressedOn(background))
        {
            setOpen(!isOpen);
            return;
        }
        if (isOpen)
        {
            for (i in 0...optionRows.length)
            {
                if (FlxG.mouse.overlaps(optionRows[i]) || TouchUtil.justPressedOn(optionRows[i]))
                {
                    selectedIndex = i;
                    setOpen(false);
                    break;
                }
            }
        }
    }

    public function setOpen(state:Bool):Void
    {
        isOpen = state;
        for (i in 0...optionRows.length)
        {
            remove(optionRows[i], true);
            remove(optionLabels[i], true);
        }
        optionRows = [];
        optionLabels = [];
        if (!isOpen) return;
        for (i in 0...options.length)
        {
            var row = new FlxSprite(0, 32 + i * rowHeight).makeGraphic(controlWidth, rowHeight, 0xFF26394D);
            var label = new FlxText(8, 39 + i * rowHeight, controlWidth - 16, options[i], 11);
            label.setFormat(null, 11, FlxColor.WHITE, LEFT);
            optionRows.push(row);
            optionLabels.push(label);
            add(row);
            add(label);
        }
    }

    private function set_selectedIndex(next:Int):Int
    {
        if (options.length == 0) selectedIndex = 0;
        else selectedIndex = next < 0 ? 0 : (next >= options.length ? options.length - 1 : next);
        refresh();
        if (onChange != null) onChange(selectedIndex, selectedValue);
        return selectedIndex;
    }

    private function refresh():Void
    {
        if (caption != null) caption.text = selectedValue + (isOpen ? "  ▲" : "  ▼");
    }
}
