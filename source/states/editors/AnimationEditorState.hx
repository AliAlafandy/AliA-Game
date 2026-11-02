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
#if sys
import sys.FileSystem;
import sys.io.File;
#end
using StringTools;

/**
 * Animation editor: browse character JSON files and edit animation definitions (names, atlas image/prefix, offsets, FPS, scale, frame indices and looping).
 * This editor edits the actual JSON file in-place and keeps its path.
 */
class AnimationEditorState extends GameState
{
	private var title:FlxText;
	private var status:FlxText;
	private var entries:FlxText;
	private var paths:Array<String> = [];
	private var selected:Int = 0;
	private var editor:TextField;
	private var editing:Bool = false;
	private var newFilePath:String = "";

	public function new():Void super();

	override public function create():Void
	{
		super.create();
		FlxG.camera.bgColor = 0xFF111722;
		var bar = new FlxSprite().makeGraphic(FlxG.width, 52, 0xFF263449);
		add(bar);
		title = new FlxText(12, 12, FlxG.width - 24, "ANIMATION EDITOR", 22);
		title.setFormat(null, 22, FlxColor.WHITE, LEFT);
		add(title);
		entries = new FlxText(14, 68, FlxG.width - 28, "", 14);
		entries.setFormat(null, 14, FlxColor.WHITE, LEFT);
		add(entries);
		status = new FlxText(12, FlxG.height - 58, FlxG.width - 24, "", 12);
		status.setFormat(null, 12, FlxColor.LIME, LEFT);
		add(status);
		scan();
		refresh();
		#if mobile
		addTouchControls();
		#end
	}

	#if mobile
	private function addTouchControls():Void
	{
		var y = FlxG.height - 88;
		var w = (FlxG.width - 24) / 5;
		var labels = ['UP', 'DOWN', 'OPEN', 'NEW', 'BACK'];
		for (i in 0...labels.length)
		{
			var index = i;
			var b = new FlxButton(4 + i * (w + 4), y, labels[i], function() {
				switch (index) {
					case 0: if (paths.length > 0) selected = (selected - 1 + paths.length) % paths.length; refresh();
					case 1: if (paths.length > 0) selected = (selected + 1) % paths.length; refresh();
					case 2: if (editing) closeEditor() else openSelected();
					case 3: createFile();
					case 4: if (editing) closeEditor() else GameState.switchState(new EditorState());
				}
			});
			b.scale.set(0.8, 0.8);
			add(b);
		}
		var saveButton = new FlxButton(FlxG.width - 72, 8, 'SAVE', save);
		saveButton.scale.set(0.8, 0.8);
		add(saveButton);
	}
	#end

	private function scan():Void
	{
		paths = [];
		#if sys
		#if MODS_ALLOWED
		var modsRoot = Paths.mods();
		if (FileSystem.exists(modsRoot))
		{
			for (mod in FileSystem.readDirectory(modsRoot))
			{
				var folder = haxe.io.Path.join([modsRoot, mod, "characters"]);
				if (FileSystem.exists(folder) && FileSystem.isDirectory(folder)) scanDir(folder);
			}
		}
		#end
		var shared = Paths.getSharedPath() + "characters/";
		if (FileSystem.exists(shared) && FileSystem.isDirectory(shared)) scanDir(shared);
		#end
		paths.sort(Reflect.compare);
	}

	private function scanDir(dir:String):Void
	{
		#if sys
		for (entry in FileSystem.readDirectory(dir))
		{
			var path = haxe.io.Path.join([dir, entry]);
			if (FileSystem.isDirectory(path)) scanDir(path);
			else if (entry.toLowerCase().endsWith(".json") && !paths.contains(path)) paths.push(path);
		}
		#end
	}

	private function refresh():Void
	{
		if (paths.length == 0)
		{
			entries.text = "No characters JSON files found. Press N to create one.";
			status.text = "Searches shared assets and every mod folder.";
			return;
		}
		selected = (selected % paths.length + paths.length) % paths.length;
		var lines:Array<String> = [];
		var start = Std.int(Math.max(0, Math.min(selected - 8, paths.length - 16)));
		for (i in start...Std.int(Math.min(paths.length, start + 16)))
			lines.push((i == selected ? "> " : "  ") + paths[i]);
		entries.text = lines.join("\n");
		status.text = paths.length + " file(s) | UP/DOWN select | ENTER edit | N new | CTRL+S save | ESC back";
	}

	private function openSelected():Void
	{
		if (paths.length > 0) openPath(paths[selected]);
	}

	private function openPath(path:String):Void
	{
		#if sys
		try
		{
			editor = new TextField();
			editor.type = TextFieldType.INPUT;
			editor.multiline = true;
			editor.wordWrap = false;
			editor.background = true;
			editor.backgroundColor = 0xFF151A22;
			editor.border = true;
			editor.borderColor = 0xFF53647A;
			editor.textColor = 0xFFFFFFFF;
			editor.defaultTextFormat = new TextFormat("_typewriter", 14, 0xFFFFFFFF);
			editor.x = 10;
			editor.y = 62;
			editor.width = FlxG.width - 20;
			editor.height = FlxG.height - 132;
			editor.text = File.getContent(path);
			editor.addEventListener(KeyboardEvent.KEY_DOWN, onEditorKey);
			FlxG.stage.addChild(editor);
			FlxG.stage.focus = editor;
			newFilePath = path;
			editing = true;
			entries.visible = false;
			status.text = path;
		}
		catch (e:Dynamic) status.text = "Open failed: " + Std.string(e);
		#end
	}

	private function onEditorKey(event:KeyboardEvent):Void
	{
		if (event.keyCode == Keyboard.S && event.ctrlKey)
		{
			event.stopImmediatePropagation();
			save();
		}
		else if (event.keyCode == Keyboard.ESCAPE)
		{
			event.stopImmediatePropagation();
			closeEditor();
		}
	}

	private function save():Void
	{
		#if sys
		if (editor == null || newFilePath.length == 0) return;
		try
		{
			// Validate JSON before overwriting the original file.
			haxe.Json.parse(editor.text);
			File.saveContent(newFilePath, editor.text);
			status.text = "Saved " + newFilePath;
		}
		catch (e:Dynamic) status.text = "Save failed (invalid JSON or write error): " + Std.string(e);
		#end
	}

	private function closeEditor():Void
	{
		if (editor != null)
		{
			editor.removeEventListener(KeyboardEvent.KEY_DOWN, onEditorKey);
			if (editor.parent != null) editor.parent.removeChild(editor);
			editor = null;
		}
		FlxG.stage.focus = null;
		editing = false;
		entries.visible = true;
		refresh();
	}

	private function createFile():Void
	{
		#if sys
		#if MODS_ALLOWED
		var root = Paths.mods();
		var mods:Array<String> = [];
		if (FileSystem.exists(root))
			for (mod in FileSystem.readDirectory(root))
			{
				var p = haxe.io.Path.join([root, mod]);
				if (FileSystem.isDirectory(p)) mods.push(mod);
			}
		if (mods.length == 0) { status.text = "Create a mod folder first."; return; }
		var dir = haxe.io.Path.join([root, mods[0], "characters"]);
		if (!FileSystem.exists(dir)) FileSystem.createDirectory(dir);
		var path = haxe.io.Path.join([dir, "new_animations.json"]);
		if (FileSystem.exists(path)) { status.text = "File already exists: " + path; return; }
		File.saveContent(path, "{\"charName\":\"NewCharacter\",\"anim\":[{\"name\":\"idle\",\"image\":\"NewCharacter\",\"prefix\":\"idle\",\"offsets\":[0,0],\"loop\":false,\"scale\":1,\"fps\":24,\"indices\":[]}]}");
		scan();
		var index = paths.indexOf(path);
		if (index >= 0) selected = index;
		refresh();
		openPath(path);
		#else
		status.text = "Mod support is disabled.";
		#end
		#end
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (editing) return;
		if (paths.length > 0 && controls.GAME_UP_P) { selected = (selected - 1 + paths.length) % paths.length; refresh(); }
		else if (paths.length > 0 && controls.GAME_DOWN_P) { selected = (selected + 1) % paths.length; refresh(); }
		if (controls.ACCEPT) openSelected();
		if (FlxG.keys.justPressed.N) createFile();
		if (controls.BACK) GameState.switchState(new EditorState());
	}
}
