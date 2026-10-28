package states.options;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class BaseOptionsMenu extends GameSubState
{
    public var category:String;
	public var title:String;

    var rows:Array<Dynamic> = [];
    var labels:Array<FlxText> = [];
    var selected:Int = 0;
	var heading:FlxText;
    var help:FlxText;

    public function new(category:String)
    {
        this.category = category;
		if(title == null) title = "Options";
        super();
		#if mobile
		// controls.isInSubstate = true;
		addCustomDPad('EXITE', 'MENU');
		addCustomDPadCam();
		#end
        buildRows();
    }

    public function buildRows():Void {}

    public function addBool(label:String, field:String, description:String):Void
        rows.push({
			label:label,
			field:field,
			description:description,
			kind:"bool"
		});

    public function addInt(label:String, field:String, description:String, min:Int, max:Int, step:Int):Void
        rows.push({
			label:label,
			field:field,
			description:description,
			kind:"int",
			min:min, max:max, step:step
		});

    public function addFloat(label:String, field:String, description:String, min:Float, max:Float, step:Float):Void
        rows.push({
			label:label,
			field:field,
			description:description,
			kind:"float",
			min:min, max:max, step:step
		});

    public function addString(label:String, field:String, description:String, values:Array<String>):Void
        rows.push({
			label:label,
			field:field,
			description:description,
			kind:"string",
			values:values
		});

    public function addDynamic(label:String, field:String, description:String, ?value:Dynamic, ?min:Float, ?max:Float, ?step:Float):Void
    {
        var choices:Array<Dynamic> = Std.isOfType(value, Array) ? cast value : null;
        var hasRange:Bool = min != null && max != null && step != null;
        rows.push({
            label: label,
            field: field,
            description: description,
            kind: "dynamic",
            values: choices,
            initialValue: value,
            mode: (choices != null || hasRange || value != null) ? "change" : "action",
            min: min == null ? 0 : min,
            max: max == null ? 1 : max,
            step: step == null ? 0.1 : step
        });
    }

    override function create():Void
    {
        super.create();
        var shade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        shade.alpha = 0.78;
        add(shade);

        heading = new FlxText(0, 24, FlxG.width, title, 32);
        heading.setFormat(null, 32, FlxColor.WHITE, CENTER);
        add(heading);

        for (i in 0...rows.length)
        {
            var label = new FlxText(70, 130 + i * 42, FlxG.width - 140, "", 22);
            label.setFormat(null, 22, FlxColor.WHITE, CENTER);
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
        if (category == "GameplaySettings" && row.field != null)
        {
            if (row.field == "timeLimit" || row.field == "debugMode" || row.field == "infiniteLife" || row.field == "infinitePower" || row.field == "timeType")
                return ClientPrefs.data.gameplaySettings.get(row.field);
        }
        return Reflect.field(ClientPrefs.data, row.field);
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
        if (category == "GameplaySettings" && (row.field == "timeLimit" || row.field == "debugMode" || row.field == "infiniteLife" || row.field == "infinitePower" || row.field == "timeType"))
        {
            ClientPrefs.data.gameplaySettings.set(row.field, value);
            return;
        }
        Reflect.setField(ClientPrefs.data, row.field, value);
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
		if (row.field == "signInAction") {
            FlxG.switchState(new states.online.AccountState());
            trace("Sign In action triggered!");
            return;
        }

        var value:Dynamic = readValue(row);
        var kind:String = row.kind;
        if (kind == "dynamic")
        {
            if (row.values != null && row.values.length > 0)
                kind = "string";
            else if (Std.isOfType(value, Bool))
                kind = "bool";
            else if (Std.isOfType(value, Int))
                kind = "int";
            else if (Std.isOfType(value, Float))
                kind = "float";
            else
                return;
        }

        switch (kind)
        {
            case "bool", "mute":
                writeValue(row, value != true);
            case "int", "float", "volume":
                var minimum:Float = row.min == null ? 0 : row.min;
                var maximum:Float = row.max == null ? 1 : row.max;
                var increment:Float = row.step == null ? 0.1 : row.step;
                var numeric:Float = value == null ? minimum : Std.parseFloat(Std.string(value));
                if (Math.isNaN(numeric)) numeric = minimum;
                numeric += increment * direction;
                if (numeric < minimum) numeric = minimum;
                if (numeric > maximum) numeric = maximum;
                if (kind == "int") writeValue(row, Std.int(numeric));
                else writeValue(row, numeric);
            case "string":
                if (row.values == null || row.values.length == 0) return;
                var idx:Int = -1;
                for (i in 0...row.values.length)
                    if (Std.string(row.values[i]) == Std.string(value)) { idx = i; break; }
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
            var value:Dynamic = readValue(row);
            var shown:String = Std.string(value);
            
            var displayKind:String = row.kind;
            if (displayKind == "dynamic")
            {
                if (row.values != null && row.values.length > 0)
                    displayKind = "string";
                else if (Std.isOfType(value, Bool))
                    displayKind = "bool";
                else if (Std.isOfType(value, Int))
                    displayKind = "int";
                else if (Std.isOfType(value, Float))
                    displayKind = "float";
            }

            switch (displayKind)
            {
                case "bool", "mute":
                    shown = (value == true) ? "ON" : "OFF";
                case "volume":
                    shown = Std.int(Std.parseFloat(Std.string(value)) * 100) + "%";
                case "float":
                    shown = Std.string(Math.round(Std.parseFloat(Std.string(value)) * 100) / 100);
                case "int":
                    shown = Std.string(Std.int(Std.parseFloat(Std.string(value))));
                case "string":
                    shown = (value == null) ? "" : Std.string(value);
            }
            
            labels[i].text = (i == selected ? "> " : "  ") + row.label + ": " + shown;
            labels[i].color = i == selected ? FlxColor.YELLOW : FlxColor.WHITE;
        }
        if (rows.length > 0) help.text = rows[selected].description; // + "\nLEFT/RIGHT: change   ENTER: toggle   ESC/BACK: return"
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (controls.UI_UP_P) { selected = (selected - 1 + rows.length) % rows.length; refresh(); }
        if (controls.UI_DOWN_P) { selected = (selected + 1) % rows.length; refresh(); }
        if (rows.length > 0)
        {
            var row = rows[selected];
            var kind:String = row.kind;
            if (kind == "dynamic")
            {
                if (row.values != null && row.values.length > 0) kind = "string";
                else if (row.mode == "action") kind = "action";
                else
                {
                    var currentValue:Dynamic = readValue(row);
                    if (Std.isOfType(currentValue, Bool)) kind = "bool";
                    else if (Std.isOfType(currentValue, Int)) kind = "int";
                    else if (Std.isOfType(currentValue, Float)) kind = "float";
                    else kind = "action";
                }
            }

            // Boolean options use ENTER, never LEFT/RIGHT.
            if ((controls.UI_LEFT_P || controls.UI_RIGHT_P) && kind != "bool" && kind != "mute" && kind != "action")
                changeValue(row, controls.UI_LEFT_P ? -1 : 1);

            if (controls.ACCEPT)
            {
                if (kind == "bool" || kind == "mute")
                    changeValue(row, 1);
                else if (kind == "action")
                {
                    if (row.field == "signInAction")
                        FlxG.switchState(new states.online.AccountState());
                    else if (Reflect.hasField(row, "onAccept") && row.onAccept != null)
                        row.onAccept();
                }
            }
        }
        if (controls.BACK)
        {
			// FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
            ClientPrefs.saveSettings();
            #if mobile
			// controls.isInSubstate = false;
			removeCustomDPad();
			#end
            close();
            FlxG.sound.play(Paths.sound("cancelMenu"));
        }
    }

    override function destroy():Void
    {
        ClientPrefs.saveSettings();
		#if mobile
		// controls.isInSubstate = false;
		removeCustomDPad();
		#end
        super.destroy();
    }
}
