package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
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
 * Global script editor.
 *
 * Scans every mod's scripts/ directory, rather than scripts belonging to
 * the currently selected song or level. Supports .ellawy, .hx and .lua.
 */
class ScriptEditorState extends GameState
{
	private var title:FlxText;
	private var help:FlxText;
	private var fileList:FlxText;
	private var status:FlxText;
	private var files:Array<String> = [];
	private var selected:Int = 0;
	private var selectedPath:String = "";
	private var editor:TextField;
	private var isEditing:Bool = false;
	private var listScroll:Int = 0;

	#if mobile
	public var manager:MobileInputManager;
	#end

	public function new():Void
	{
		super();
		#if mobile
		manager = new MobileInputManager();
		#end
	}

	override public function create():Void
	{
		super.create();
		FlxG.camera.bgColor = 0xFF10131B;

		var header = new FlxSprite(0, 0);
		header.makeGraphic(FlxG.width, 54, 0xFF202A3A);
		add(header);

		title = new FlxText(12, 12, FlxG.width - 24, "GLOBAL MOD SCRIPT EDITOR", 22);
		title.setFormat(null, 22, FlxColor.WHITE, LEFT);
		add(title);

		fileList = new FlxText(14, 70, FlxG.width - 28, "", 15);
		fileList.setFormat(null, 15, FlxColor.WHITE, LEFT);
		add(fileList);

		status = new FlxText(14, FlxG.height - 62, FlxG.width - 28, "Scanning mods...", 13);
		status.setFormat(null, 13, FlxColor.LIME, LEFT);
		add(status);

		help = new FlxText(14, FlxG.height - 40, FlxG.width - 28,
			"UP/DOWN Select  ENTER Open  N New  CTRL+S Save  BACK Return", 12);
		help.setFormat(null, 12, FlxColor.GRAY, LEFT);
		add(help);

		scanScripts();
		refreshList();

		#if mobile
		addCustomDPad('NONE', 'BACK');
		addCustomDPadCam();
		#end
	}

	private function scanScripts():Void
	{
		files = [];
		#if sys
		#if MODS_ALLOWED
		var root:String = Paths.mods();
		if (FileSystem.exists(root))
		{
			for (mod in FileSystem.readDirectory(root))
			{
				var modPath = haxe.io.Path.join([root, mod]);
				if (!FileSystem.isDirectory(modPath)) continue;

				var scriptsPath = haxe.io.Path.join([modPath, "scripts"]);
				if (!FileSystem.exists(scriptsPath) || !FileSystem.isDirectory(scriptsPath)) continue;

				scanDirectory(scriptsPath);
			}
		}

		// Also include the shared game's scripts directory.
		var sharedScripts = Paths.getSharedPath() + "scripts/";
		if (FileSystem.exists(sharedScripts) && FileSystem.isDirectory(sharedScripts))
			scanDirectory(sharedScripts);
		#end
		#end
		files.sort(Reflect.compare);
	}

	private function scanDirectory(directory:String):Void
	{
		#if sys
		try
		{
			for (entry in FileSystem.readDirectory(directory))
			{
				var fullPath = haxe.io.Path.join([directory, entry]);
				if (FileSystem.isDirectory(fullPath))
				{
					scanDirectory(fullPath);
					continue;
				}

				var lower = entry.toLowerCase();
				if (lower.endsWith(".ellawy") || lower.endsWith(".hx") || lower.endsWith(".lua"))
					if (!files.contains(fullPath)) files.push(fullPath);
			}
		}
		catch (e:Dynamic)
		{
			trace('[ScriptEditor] Could not scan $directory: $e');
		}
		#end
	}

	private function refreshList():Void
	{
		if (files.length == 0)
		{
			fileList.text = "No scripts found. Press N to create a script in the selected mod.";
			return;
		}

		selected = FlxMath.wrap(selected, 0, files.length - 1);
		var start = Std.int(Math.max(0, Math.min(selected - 8, files.length - 16)));
		listScroll = start;
		var lines:Array<String> = [];
		for (i in start...Std.int(Math.min(files.length, start + 16)))
		{
			var prefix = i == selected ? "> " : "  ";
			lines.push(prefix + files[i]);
		}
		fileList.text = lines.join("\n");
		status.text = files.length + " script(s) found";
	}

	private function openSelected():Void
	{
		if (files.length == 0) return;
		openFile(files[selected]);
	}

	private function openFile(path:String):Void
	{
		#if sys
		try
		{
			var source = File.getContent(path);
			selectedPath = path;
			isEditing = true;

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
			editor.x = 12;
			editor.y = 66;
			editor.width = FlxG.width - 24;
			editor.height = FlxG.height - 142;
			editor.text = source;
			editor.addEventListener(KeyboardEvent.KEY_DOWN, onEditorKeyDown);
			FlxG.stage.addChild(editor);

			fileList.visible = false;
			help.text = "CTRL+S Save  ESC Close Editor";
			status.text = "Editing: " + path;
			FlxG.stage.focus = editor;
		}
		catch (e:Dynamic)
		{
			status.text = "Open failed: " + Std.string(e);
		}
		#end
	}

	private function onEditorKeyDown(event:KeyboardEvent):Void
	{
		if (event.keyCode == Keyboard.S && event.ctrlKey)
		{
			event.stopImmediatePropagation();
			saveCurrent();
		}
		else if (event.keyCode == Keyboard.ESCAPE)
		{
			event.stopImmediatePropagation();
			closeEditor();
		}
	}

	private function saveCurrent():Void
	{
		#if sys
		if (editor == null || selectedPath.length == 0) return;
		try
		{
			File.saveContent(selectedPath, editor.text);
			status.text = "Saved: " + selectedPath;
		}
		catch (e:Dynamic)
		{
			status.text = "Save failed: " + Std.string(e);
		}
		#end
	}

	private function closeEditor():Void
	{
		if (editor != null)
		{
			editor.removeEventListener(KeyboardEvent.KEY_DOWN, onEditorKeyDown);
			if (editor.parent != null) editor.parent.removeChild(editor);
			editor = null;
		}
		FlxG.stage.focus = null;
		isEditing = false;
		fileList.visible = true;
		help.text = "UP/DOWN Select  ENTER Open  N New  CTRL+S Save  BACK Return";
		refreshList();
	}

	private function createNewScript():Void
	{
		#if sys
		#if MODS_ALLOWED
		var modsRoot = Paths.mods();
		var modFolders:Array<String> = [];
		if (FileSystem.exists(modsRoot))
		{
			for (folder in FileSystem.readDirectory(modsRoot))
			{
				var path = haxe.io.Path.join([modsRoot, folder]);
				if (FileSystem.isDirectory(path)) modFolders.push(folder);
			}
		}

		if (modFolders.length == 0)
		{
			status.text = "Create a mod folder first.";
			return;
		}

		// New scripts are created in the first available mod's scripts folder.
		// Existing scripts from every mod remain editable in the same list.
		var scriptsDir = haxe.io.Path.join([modsRoot, modFolders[0], "scripts"]);
		if (!FileSystem.exists(scriptsDir)) FileSystem.createDirectory(scriptsDir);

		var base = "new_script.ellawy";
		var path = haxe.io.Path.join([scriptsDir, base]);
		var index = 1;
		while (FileSystem.exists(path))
		{
			path = haxe.io.Path.join([scriptsDir, 'new_script_$index.ellawy']);
			index++;
		}
		File.saveContent(path, "// Global mod script\n\nfunction onGame()\n{\n}\nend\n");
		scanScripts();
		var found = files.indexOf(path);
		if (found >= 0) selected = found;
		refreshList();
		openFile(path);
		#else
		status.text = "Mod support is disabled in this build.";
		#end
		#end
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (isEditing) return;

		if (controls.GAME_UP_P)
		{
			selected = FlxMath.wrap(selected - 1, 0, files.length - 1);
			refreshList();
		}
		else if (controls.GAME_DOWN_P)
		{
			selected = FlxMath.wrap(selected + 1, 0, files.length - 1);
			refreshList();
		}

		if (controls.ACCEPT) openSelected();
		if (FlxG.keys.justPressed.N) createNewScript();

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound("cancel_sound"));
			GameState.switchState(new EditorState());
		}
	}

	override public function destroy():Void
	{
		if (editor != null) closeEditor();
		super.destroy();
	}
}
