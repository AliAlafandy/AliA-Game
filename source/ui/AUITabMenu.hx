package ui;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/** Horizontal tab strip with a content panel and selection callback. */
class AUITabMenu extends FlxGroup
{
    public var tabs:Array<String>;
    public var selectedIndex(default, set):Int = 0;
    public var contentPanel:FlxSprite;
    public var onChange:Int->String->Void;
    public var tabButtons:Array<AUIButton> = [];
    private var tabWidth:Int;
    private var panelWidth:Int;
    private var panelHeight:Int;

    public function new(x:Float, y:Float, width:Int, height:Int, tabs:Array<String>, ?callback:Int->String->Void)
    {
        super();
        this.tabs = tabs == null ? [] : tabs.copy();
        onChange = callback;
        panelWidth = width;
        panelHeight = height;
        tabWidth = this.tabs.length == 0 ? width : Std.int(width / this.tabs.length);
        for (i in 0...this.tabs.length)
        {
            final index = i;
            var button = new AUIButton(x + i * tabWidth, y, tabWidth, 30, this.tabs[i], function() selectedIndex = index);
            tabButtons.push(button);
            add(button);
        }
        contentPanel = new FlxSprite(x, y + 34).makeGraphic(width, height, 0xFF172332);
        add(contentPanel);
        selectedIndex = 0;
    }

    private function set_selectedIndex(next:Int):Int
    {
        if (tabs.length == 0) selectedIndex = 0;
        else selectedIndex = next < 0 ? 0 : (next >= tabs.length ? tabs.length - 1 : next);
        for (i in 0...tabButtons.length)
            tabButtons[i].setEnabled(i != selectedIndex);
        if (onChange != null && tabs.length > 0) onChange(selectedIndex, tabs[selectedIndex]);
        return selectedIndex;
    }
}
