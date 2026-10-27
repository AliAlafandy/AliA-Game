package states.options;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class BaseOptionsMenu extends GameSubState
{
    public var category:String;
    var rows:Array<Dynamic> = [];
    var labels:Array<FlxText> = [];
    var selected:Int = 0;
    var heading:FlxText;
    var help:FlxText;

    public function new(category:String)
    {
        this.category = category;
        super();
        #if mobile controls.isInSubstate = true; #end
        buildRows();
    }

    public function buildRows():Void {}

    public function addBool(label:String, field:String, description:String):Void
        rows.push({label:label, field:field, kind:"bool", description:description});

    public function addInt(label:String, field:String, min:Int, max:Int, step:Int, description:String):Void
        rows.push({label:label, field:field, kind:"int", min:min, max:max, step:step, description:description});

    public function addFloat(label:String, field:String, min:Float, max:Float, step:Float, description:String):Void
        rows.push({label:label, field:field, kind:"float", min:min, max:max, step:step, description:description});

    public function addString(label:String, field:String, values:Array<String>, description:String):Void
        rows.push({label:label, field:field, kind:"string", values:values, description:description});

    override function create():Void
    {
        super.create();
        var shade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        shade.alpha = 0.78;
        add(shade);

        heading = new FlxText(0, 24, FlxG.width, category.toUpperCase() + " SETTINGS", 32);
        heading.setFormat(null, 32, FlxColor.WHITE, CENTER);
        add(heading);

        for (i in 0...rows.length)
        {
            var label = new FlxText(70, 100 + i * 42, FlxG.width - 140, "", 22);
            label.setFormat(null, 22, FlxColor.WHITE, LEFT);
            label.scrollFactor.set();
            labels.push(label);
            add(label);
        }

        help = new FlxText(35, FlxG.height - 72, FlxG.width - 70, "", 16);
        help.setFormat(null, 16, FlxColor.WHITE, CENTER);
        add(help);
        refresh();
    }

    function readValue(row:Dynamic):Dynamic
    {
        if (row.kind == "volume") return FlxG.sound.volume;
        if (row.kind == "mute") return FlxG.sound.muted;
        if (category == "Gameplay" && row.field != null)
        {
            if (row.field == "timeLimit" || row.field == "debugMode" || row.field == "infiniteLife" || row.field == "infinitePower" || row.field == "timeType")
                return ClientPrefs.data.gameplaySettings.get(row.field);
        }
        return Reflect.getProperty(ClientPrefs.data, row.field);
    }

    function writeValue(row:Dynamic, value:Dynamic):Void
    {
        if (row.kind == "volume")
        {
            FlxG.sound.volume = value;
            FlxG.save.data.volume = value;
            return;
        }
        if (row.kind == "mute")
        {
            FlxG.sound.muted = value;
            FlxG.save.data.mute = value;
            return;
        }
        if (category == "Gameplay" && (row.field == "timeLimit" || row.field == "debugMode" || row.field == "infiniteLife" || row.field == "infinitePower" || row.field == "timeType"))
        {
            ClientPrefs.data.gameplaySettings.set(row.field, value);
            return;
        }
        Reflect.setProperty(ClientPrefs.data, row.field, value);
        if (row.field == "showFPS" && Main.fpsVar != null) Main.fpsVar.visible = value;
        if (row.field == "framerate")
        {
            FlxG.updateFramerate = value;
            FlxG.drawFramerate = value;
        }
        #if mobile
        if (row.field == "vibration") mobile.data.debug.Vibration.enabled = value;
        #end
    }

    function changeValue(row:Dynamic, direction:Int):Void
    {
        var value:Dynamic = readValue(row);
        switch (row.kind)
        {
            case "bool", "mute":
                writeValue(row, value != true);
            case "int", "float", "volume":
                value = (value == null ? row.min : value) + row.step * direction;
                if (value < row.min) value = row.max;
                if (value > row.max) value = row.min;
                if (row.kind == "int") value = Std.int(value);
                writeValue(row, value);
            case "string":
                var idx:Int = row.values.indexOf(Std.string(value));
                if (idx < 0) idx = 0;
                idx = Std.int((idx + direction + row.values.length) % row.values.length);
                writeValue(row, row.values[idx]);
        }
        ClientPrefs.saveSettings();
        refresh();
    }

    function refresh():Void
    {
        for (i in 0...rows.length)
        {
            var row = rows[i];
            var value = readValue(row);
            var shown:String = Std.string(value);
            if (row.kind == "bool" || row.kind == "mute") shown = value == true ? "ON" : "OFF";
            if (row.kind == "volume") shown = Std.int(Std.parseFloat(Std.string(value)) * 100) + "%";
            labels[i].text = (i == selected ? "> " : "  ") + row.label + ": " + shown;
            labels[i].color = i == selected ? FlxColor.YELLOW : FlxColor.WHITE;
        }
        if (rows.length > 0) help.text = rows[selected].description + "\nLEFT/RIGHT: change   ENTER: toggle   ESC/BACK: return";
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (controls.UI_UP_P) { selected = (selected - 1 + rows.length) % rows.length; refresh(); }
        if (controls.UI_DOWN_P) { selected = (selected + 1) % rows.length; refresh(); }
        if (rows.length > 0 && (controls.UI_LEFT_P || controls.UI_RIGHT_P))
            changeValue(rows[selected], controls.UI_LEFT_P ? -1 : 1);
        if (rows.length > 0 && controls.ACCEPT && (rows[selected].kind == "bool" || rows[selected].kind == "mute"))
            changeValue(rows[selected], 1);
        if (controls.BACK)
        {
            ClientPrefs.saveSettings();
            #if mobile controls.isInSubstate = false; #end
            close();
            FlxG.sound.play(Paths.sound("cancelMenu"));
        }
    }

    override function destroy():Void
    {
        ClientPrefs.saveSettings();
		#if mobile controls.isInSubstate = false; #end
        super.destroy();
    }
}
