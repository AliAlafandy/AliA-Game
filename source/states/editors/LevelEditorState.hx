package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import data.backend.LevelBin;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

/**
 * Level.bin editor. The JSON-like text panel is an editable inspector for
 * the exact LevelBin schema. Export converts it to the game's binary BIN.
 */
class LevelEditorState extends GameState
{
	private var title:FlxText;
	private var help:FlxText;
	private var status:FlxText;
	private var editor:TextField;
	private var levelName:String = "ATown";
	private var editorOpen:Bool = false;
	private var previewGroup:flixel.group.FlxGroup.FlxTypedGroup<FlxSprite>;
	private var previewFlash:FlxSprite;
	private var previewBackground:FlxSprite;
	private var mobileButtons:Array<FlxButton> = [];

	private var document:String = "";

	public function new(?name:String = "ATown", ?c:Int = 40, ?r:Int = 24)
	{
		super();
		levelName = name;
	}

	override public function create():Void
	{
		super.create();
		FlxG.camera.bgColor = 0xFF101722;

		title = new FlxText(12, 10, FlxG.width - 24, "LEVEL.BIN EDITOR", 22);
		title.setFormat(null, 22, FlxColor.WHITE, LEFT);
		add(title);

		help = new FlxText(12, 42, FlxG.width - 24,
			"Edit stage properties and object arrays. Export writes Level.bin in the LevelBin format.", 12);
		help.setFormat(null, 12, FlxColor.CYAN, LEFT);
		add(help);

		status = new FlxText(12, FlxG.height - 74, FlxG.width - 24, "", 12);
		status.setFormat(null, 12, FlxColor.LIME, LEFT);
		add(status);

		previewGroup = new flixel.group.FlxGroup.FlxTypedGroup<FlxSprite>();
		add(previewGroup);

		loadDefaultDocument();
		openInspector();
		addButtons();
		refreshPreview();
	}

	private function loadDefaultDocument():Void
	{
		document = '{\n'
			+ '  "name": "' + levelName + '",\n'
			+ '  "music": "levels/' + levelName + '/theme",\n'
			+ '  "player": { "x": 160, "y": 420 },\n'
			+ '  "backgrounds": [\n'
			+ '    { "image": "levels/' + levelName + '/background", "x": 0, "y": 0, "scrollX": 350, "scrollY": 350 }\n'
			+ '  ],\n'
			+ '  "flashes": [\n'
			+ '    { "x": 420, "y": 380, "value": 1 }\n'
			+ '  ]\n'
			+ '}';
	}

	private function openInspector():Void
	{
		editor = new TextField();
		editor.type = TextFieldType.INPUT;
		editor.multiline = true;
		editor.wordWrap = false;
		editor.background = true;
		editor.backgroundColor = 0xFF171F2B;
		editor.border = true;
		editor.borderColor = 0xFF52647B;
		editor.textColor = 0xFFFFFFFF;
		editor.defaultTextFormat = new TextFormat("_typewriter", 14, 0xFFFFFFFF);
		editor.x = 12;
		editor.y = 72;
		editor.width = FlxG.width - 24;
		editor.height = FlxG.height - 164;
		editor.text = document;
		editor.addEventListener(KeyboardEvent.KEY_DOWN, onEditorKey);
		FlxG.stage.addChild(editor);
		FlxG.stage.focus = editor;
		editorOpen = true;
	}

	private function onEditorKey(event:KeyboardEvent):Void
	{
		if (event.keyCode == Keyboard.S && event.ctrlKey)
		{
			event.stopImmediatePropagation();
			exportLevel();
		}
		else if (event.keyCode == Keyboard.ESCAPE)
		{
			event.stopImmediatePropagation();
			FlxG.stage.focus = null;
		}
	}

	private function addButtons():Void
	{
		#if mobile
		var labels = ["ADD FLASH", "ADD BG", "LOAD", "EXPORT", "BACK"];
		var width = (FlxG.width - 24) / labels.length;
		for (i in 0...labels.length)
		{
			var index = i;
			var button = new FlxButton(4 + i * (width + 4), FlxG.height - 42, labels[i], function() {
				switch (index)
				{
					case 0: appendFlash();
					case 1: appendBackground();
					case 2: loadLevel();
					case 3: exportLevel();
					case 4: leaveEditor();
				}
			});
			button.scale.set(0.78, 0.78);
			mobileButtons.push(button);
			add(button);
		}
		#else
		var exportButton = new FlxButton(FlxG.width - 104, 8, "EXPORT", exportLevel);
		add(exportButton);
		var loadButton = new FlxButton(FlxG.width - 204, 8, "LOAD", loadLevel);
		add(loadButton);
		#end
	}

	private function appendFlash():Void
	{
		if (editor == null) return;
		try
		{
			var root:Dynamic = haxe.Json.parse(editor.text);
			if (root.flashes == null) root.flashes = [];
			root.flashes.push({x: 500, y: 380, value: 1});
			editor.text = haxe.Json.stringify(root, null, "  ");
			status.text = "Added a flash collectible. Edit its x, y and value.";
		}
		catch (e:Dynamic) status.text = "Fix JSON syntax before adding an object: " + Std.string(e);
	}

	private function appendBackground():Void
	{
		if (editor == null) return;
		try
		{
			var root:Dynamic = haxe.Json.parse(editor.text);
			if (root.backgrounds == null) root.backgrounds = [];
			root.backgrounds.push({image: "levels/" + levelName + "/background", x: 0, y: 0, scrollX: 350, scrollY: 350});
			editor.text = haxe.Json.stringify(root, null, "  ");
			status.text = "Added a background layer. Set its image path and parallax values.";
		}
		catch (e:Dynamic) status.text = "Fix JSON syntax before adding an object: " + Std.string(e);
	}

	private function validateDocument():Dynamic
	{
		if (editor == null) throw "Editor is not ready";
		var root:Dynamic = haxe.Json.parse(editor.text);
		if (root == null || root.name == null) throw "Missing required 'name' field";
		if (root.player == null || root.player.x == null || root.player.y == null) throw "Player requires x and y";
		if (root.backgrounds != null && !Std.isOfType(root.backgrounds, Array)) throw "'backgrounds' must be an array";
		if (root.flashes != null && !Std.isOfType(root.flashes, Array)) throw "'flashes' must be an array";
		if (root.music == null) root.music = "";
		if (root.backgrounds == null) root.backgrounds = [];
		if (root.flashes == null) root.flashes = [];
		return root;
	}

	private function exportLevel():Void
	{
		#if sys
		try
		{
			var root = validateDocument();
			var backgrounds = new bin.BINArray();
			for (item in (cast root.backgrounds:Array<Dynamic>))
			{
				var bg = new bin.BINObject();
				bg.set("image", bin.BINValue.string(Std.string(item.image)));
				bg.set("x", bin.BINValue.int(Std.int(item.x)));
				bg.set("y", bin.BINValue.int(Std.int(item.y)));
				bg.set("scrollX", bin.BINValue.int(item.scrollX == null ? 1000 : Std.int(item.scrollX)));
				bg.set("scrollY", bin.BINValue.int(item.scrollY == null ? 1000 : Std.int(item.scrollY)));
				backgrounds.push(bin.BINValue.object(bg));
			}

			var flashes = new bin.BINArray();
			for (item in (cast root.flashes:Array<Dynamic>))
			{
				var flash = new bin.BINObject();
				flash.set("x", bin.BINValue.int(Std.int(item.x)));
				flash.set("y", bin.BINValue.int(Std.int(item.y)));
				flash.set("value", bin.BINValue.int(item.value == null ? 1 : Std.int(item.value)));
				flashes.push(bin.BINValue.object(flash));
			}

			var player = new bin.BINObject();
			player.set("x", bin.BINValue.int(Std.int(root.player.x)));
			player.set("y", bin.BINValue.int(Std.int(root.player.y)));

			var level = new bin.BINObject();
			level.set("name", bin.BINValue.string(Std.string(root.name)));
			level.set("music", bin.BINValue.string(Std.string(root.music)));
			level.set("player", bin.BINValue.object(player));
			level.set("backgrounds", bin.BINValue.array(backgrounds));
			level.set("flashes", bin.BINValue.array(flashes));

			var outputDir = "assets/levels/" + Std.string(root.name);
			if (!FileSystem.exists(outputDir)) FileSystem.createDirectory(outputDir);
			var outputPath = outputDir + "/Level.bin";
			bin.BIN.save(outputPath, bin.BINValue.object(level));
			levelName = Std.string(root.name);
			status.text = "Exported " + outputPath;
		}
		catch (e:Dynamic)
		{
			status.text = "Export failed: " + Std.string(e);
		}
		#else
		status.text = "Export requires filesystem support.";
		#end
	}

	private function loadLevel():Void
	{
		#if sys
		var path = "assets/levels/" + levelName + "/Level.bin";
		if (!FileSystem.exists(path))
		{
			status.text = "No Level.bin found at " + path;
			return;
		}
		try
		{
			var obj = bin.BIN.read(path).asObject();
			var player = obj.get("player").asObject();
			var backgrounds = obj.get("backgrounds").asArray();
			var flashes = obj.get("flashes").asArray();
			var root:Dynamic = {
				name: obj.get("name").asString(levelName),
				music: obj.get("music").asString(""),
				player: {x: player == null ? 160 : player.get("x").asInt(160), y: player == null ? 420 : player.get("y").asInt(420)},
				backgrounds: [],
				flashes: []
			};
			if (backgrounds != null)
				for (i in 0...backgrounds.length)
				{
					var bg = backgrounds.get(i).asObject();
					if (bg != null) root.backgrounds.push({
						image: bg.get("image").asString(""), x: bg.get("x").asInt(0), y: bg.get("y").asInt(0),
						scrollX: bg.get("scrollX").asInt(1000), scrollY: bg.get("scrollY").asInt(1000)
					});
				}
			if (flashes != null)
				for (i in 0...flashes.length)
				{
					var fl = flashes.get(i).asObject();
					if (fl != null) root.flashes.push({x: fl.get("x").asInt(0), y: fl.get("y").asInt(0), value: fl.get("value").asInt(1)});
				}
			editor.text = haxe.Json.stringify(root, null, "  ");
			levelName = root.name;
			status.text = "Loaded " + path;
		}
		catch (e:Dynamic) status.text = "Load failed: " + Std.string(e);
		#end
	}

	private function refreshPreview():Void
	{
		// Flash preview uses the same image asset as runtime collectibles.
		previewFlash = new FlxSprite(12, 104);
		previewFlash.loadGraphic(Paths.image("display/flash"));
		previewFlash.setGraphicSize(24, 24);
		previewFlash.updateHitbox();
		previewGroup.add(previewFlash);
	}

	private function leaveEditor():Void
	{
		if (editor != null)
		{
			editor.removeEventListener(KeyboardEvent.KEY_DOWN, onEditorKey);
			if (editor.parent != null) editor.parent.removeChild(editor);
			editor = null;
		}
		FlxG.stage.focus = null;
		GameState.switchState(new EditorState());
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.ESCAPE && !editorOpen) leaveEditor();
		if (controls.BACK) leaveEditor();
	}

	override public function destroy():Void
	{
		if (editor != null)
		{
			editor.removeEventListener(KeyboardEvent.KEY_DOWN, onEditorKey);
			if (editor.parent != null) editor.parent.removeChild(editor);
		}
		super.destroy();
	}
}
