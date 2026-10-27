package substates.options;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import data.backend.ClientPrefs;

/**
 * Small shared settings menu. It edits ClientPrefs.data in-place and only
 * saves on exit; it deliberately does NOT call loadPrefs(), which would
 * overwrite the user's unsaved changes from disk.
 */
class SettingsSubState extends GameSubState
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
        controls.isInSubstate = true;
        buildRows();
    }

    function addBool(label:String, field:String, description:String):Void
        rows.push({label:label, field:field, kind:"bool", description:description});

    function addInt(label:String, field:String, min:Int, max:Int, step:Int, description:String):Void
        rows.push({label:label, field:field, kind:"int", min:min, max:max, step:step, description:description});

    function addFloat(label:String, field:String, min:Float, max:Float, step:Float, description:String):Void
        rows.push({label:label, field:field, kind:"float", min:min, max:max, step:step, description:description});

    function addString(label:String, field:String, values:Array<String>, description:String):Void
        rows.push({label:label, field:field, kind:"string", values:values, description:description});

    function buildRows():Void
    {
        switch (category)
        {
            case "Data":
                addBool("Check for updates", "checkForUpdates", "Check for game updates.");
                addBool("Loading screen", "loadingScreen", "Show the loading screen.");
                addBool("Screensaver", "screensaver", "Enable the screensaver.");
                addBool("Auto pause", "autoPause", "Pause when the app loses focus.");
                #if android
                addString("Storage type", "storageType", ["EXTERNAL_DATA"], "Storage location used by the Android build.");
                #end
            case "Controls":
                addString("Controls color", "controlsColor", ["Yellow", "Blue", "Red", "Green", "Purple", "White"], "Color theme for mobile controls.");
                addInt("Controls size", "controlsSize", 1, 4, 1, "Scale of mobile controls.");
                addFloat("Controls alpha", "controlsAlpha", 0.1, 1.0, 0.1, "Opacity of mobile controls.");
                addBool("Vibration", "vibration", "Enable supported device vibration.");
                addString("Hitbox style", "hitboxType", ["Gradient", "Normal", "No Gradient"], "Mobile touch hitbox style.");
                addString("Extra buttons", "extraButtons", ["NONE", "A", "B", "A_B", "A_B_C"], "Extra mobile buttons.");
            case "Graphics":
                addBool("Show FPS", "showFPS", "Show the FPS counter.");
                addInt("Framerate", "framerate", 30, 240, 30, "Target update and draw frame rate.");
                addBool("Antialiasing", "antialiasing", "Smooth non-pixel graphics.");
                addBool("Flashing lights", "flashing", "Allow flashing visual effects.");
                addBool("Shaders", "shaders", "Enable supported shaders.");
                addBool("VSync", "vsync", "Enable vertical synchronization where supported.");
                addBool("Wide screen", "wideScreen", "Enable wide-screen layout where supported.");
                addString("Theme", "themes", ["Normal", "Dark", "Light"], "Menu theme.");
            case "Audio":
                rows.push({label:"Master volume", field:"volume", kind:"volume", min:0.0, max:1.0, step:0.1, description:"Master game volume."});
                rows.push({label:"Mute", field:"mute", kind:"mute", description:"Mute all game audio."});
            case "Gameplay":
                addBool("Down scroll", "downscroll", "Place gameplay notes at the bottom when supported.");
                addFloat("Safe frames", "safeFrames", 0.0, 20.0, 0.5, "Input timing window.");
                addBool("Instakill on miss", "instakill", "Fail immediately after a miss.");
                addBool("Practice mode", "practice", "Enable practice gameplay.");
                addBool("Botplay", "botplay", "Enable automatic play where supported.");
                addBool("Opponent play", "opponentplay", "Enable opponent-controlled gameplay where supported.");
        }
    }

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
            if (row.field == "instakill" || row.field == "practice" || row.field == "botplay" || row.field == "opponentplay")
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
        if (category == "Gameplay" && (row.field == "instakill" || row.field == "practice" || row.field == "botplay" || row.field == "opponentplay"))
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
        if (row.field == "vibration") mobile.backend.Vibration.enabled = value;
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
                idx = (idx + direction + row.values.length) % row.values.length;
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
            if (row.kind == "volume") shown = Std.int(value * 100) + "%";
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
            controls.isInSubstate = false;
            close();
            FlxG.sound.play(Paths.sound("cancelMenu"));
        }
    }

    override function destroy():Void
    {
        ClientPrefs.saveSettings();
        controls.isInSubstate = false;
        super.destroy();
    }
}