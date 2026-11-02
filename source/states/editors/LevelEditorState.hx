package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import flixel.group.FlxGroup.FlxTypedGroup;
import data.backend.LevelBin;
import haxe.io.Bytes;
import lime.utils.Resource;

#if sys
import sys.FileSystem;
#end

#if ios
import lime.ui.FileDialog;
import lime.system.System;
#end

/**
 * Visual level editor.
 * Level data is edited through scene objects and property controls.
 * Level.bin is read/written as binary using the same BIN API as LevelBin.
 */
class LevelEditorState extends GameState
{
	private var levelName:String = "ATown";
	private var level:LevelBin;
	private var title:FlxText;
	private var status:FlxText;
	private var objectList:FlxText;
	private var properties:FlxText;
	private var preview:FlxTypedGroup<FlxSprite>;
	private var selectedKind:Int = 0;
	private var selectedIndex:Int = 0;
	private var playerMarker:FlxSprite;
	private var dragging:Bool = false;

	public function new(?name:String = "ATown", ?c:Int = 40, ?r:Int = 24)
	{
		super();
		levelName = name;
	}

	override public function create():Void
	{
		super.create();
		FlxG.camera.bgColor = 0xFF101722;
		level = LevelBin.load(levelName);
		if (level == null)
		{
			level = new LevelBin();
			level.name = levelName;
			level.playerX = 160;
			level.playerY = 420;
			level.music = "levels/" + levelName + "/theme";
			level.backgrounds.push({image: "levels/" + levelName + "/background", x: 0, y: 0, scrollX: 350, scrollY: 350});
			level.flashes.push({x: 420, y: 380, value: 1});
		}
		levelName = level.name;

		var top = new FlxSprite(0, 0).makeGraphic(FlxG.width, 48, 0xFF263449);
		add(top);
		title = new FlxText(12, 12, FlxG.width - 24, "LEVEL EDITOR  /  " + levelName, 20);
		title.setFormat(null, 20, FlxColor.WHITE, LEFT);
		add(title);

		var canvasX = 12;
		var canvasY = 62;
		var canvasW = Std.int(FlxG.width * 0.62);
		var canvasH = FlxG.height - 160;
		var canvas = new FlxSprite(canvasX, canvasY).makeGraphic(canvasW, canvasH, 0xFF182331);
		add(canvas);
		var grid = new FlxSprite(canvasX, canvasY).makeGraphic(canvasW, canvasH, FlxColor.TRANSPARENT);
		add(grid);
		preview = new FlxTypedGroup<FlxSprite>();
		add(preview);

		objectList = new FlxText(canvasX + canvasW + 12, canvasY, FlxG.width - canvasW - 36, "", 13);
		objectList.setFormat(null, 13, FlxColor.WHITE, LEFT);
		add(objectList);
		properties = new FlxText(canvasX + canvasW + 12, canvasY + 150, FlxG.width - canvasW - 36, "", 13);
		properties.setFormat(null, 13, FlxColor.CYAN, LEFT);
		add(properties);

		status = new FlxText(12, FlxG.height - 62, FlxG.width - 24, "", 12);
		status.setFormat(null, 12, FlxColor.LIME, LEFT);
		add(status);

		addButton(8, "PLAYER", function() { selectedKind = 0; selectedIndex = 0; refreshUI(); });
		addButton(1, "BACK", leaveEditor);
		addButton(2, "ADD BG", addBackground);
		addButton(3, "ADD FLASH", addFlash);
		addButton(4, "REMOVE", removeSelected);
		addButton(5, "X-", function() adjust(-16, 0));
		addButton(6, "X+", function() adjust(16, 0));
		addButton(7, "Y-", function() adjust(0, -16));
		addButton(8, "Y+", function() adjust(0, 16));
		addButton(9, "SAVE BIN", saveLevel);
		addButton(10, "LOAD BIN", loadLevel);
		refreshUI();
	}

	private function addButton(slot:Int, label:String, callback:Void->Void):Void
	{
		var row = slot <= 5 ? 0 : 1;
		var col = slot <= 5 ? slot - 1 : slot - 6;
		var count = row == 0 ? 5 : 5;
		var w = (FlxG.width - 16) / count;
		var b = new FlxButton(8 + col * w, FlxG.height - 104 + row * 34, label, callback);
		b.scale.set(0.82, 0.82);
		add(b);
	}

	private function addBackground():Void
	{
		level.backgrounds.push({image: "levels/" + levelName + "/background", x: 0, y: 0, scrollX: 1000, scrollY: 1000});
		selectedKind = 1;
		selectedIndex = level.backgrounds.length - 1;
		refreshUI();
		status.text = "Background layer added. Select it and adjust its position.";
	}

	private function addFlash():Void
	{
		level.flashes.push({x: level.playerX + 96, y: level.playerY, value: 1});
		selectedKind = 2;
		selectedIndex = level.flashes.length - 1;
		refreshUI();
		status.text = "Collectible added to the level.";
	}

	private function removeSelected():Void
	{
		if (selectedKind == 1 && level.backgrounds.length > 0)
			level.backgrounds.splice(selectedIndex, 1);
		else if (selectedKind == 2 && level.flashes.length > 0)
			level.flashes.splice(selectedIndex, 1);
		selectedIndex = 0;
		refreshUI();
	}

	private function adjust(dx:Int, dy:Int):Void
	{
		switch (selectedKind)
		{
			case 0: level.playerX += dx; level.playerY += dy;
			case 1:
				if (selectedIndex >= 0 && selectedIndex < level.backgrounds.length)
				{
					level.backgrounds[selectedIndex].x += dx;
					level.backgrounds[selectedIndex].y += dy;
				}
			case 2:
				if (selectedIndex >= 0 && selectedIndex < level.flashes.length)
				{
					level.flashes[selectedIndex].x += dx;
					level.flashes[selectedIndex].y += dy;
				}
		}
		refreshUI();
	}

	private function refreshUI():Void
	{
		if (level == null) return;
		title.text = "LEVEL EDITOR  /  " + level.name;
		var lines = ["OBJECTS", "----------------", "PLAYER  " + (selectedKind == 0 ? "<" : ""), "BACKGROUNDS (" + level.backgrounds.length + ")"];
		for (i in 0...level.backgrounds.length) lines.push("  BG " + i + (selectedKind == 1 && selectedIndex == i ? "  <" : ""));
		lines.push("FLASHES (" + level.flashes.length + ")");
		for (i in 0...level.flashes.length) lines.push("  FLASH " + i + (selectedKind == 2 && selectedIndex == i ? "  <" : ""));
		objectList.text = lines.join("\n");

		var px = selectedKind == 0 ? level.playerX : selectedKind == 1 && selectedIndex < level.backgrounds.length ? level.backgrounds[selectedIndex].x : selectedKind == 2 && selectedIndex < level.flashes.length ? level.flashes[selectedIndex].x : 0;
		var py = selectedKind == 0 ? level.playerY : selectedKind == 1 && selectedIndex < level.backgrounds.length ? level.backgrounds[selectedIndex].y : selectedKind == 2 && selectedIndex < level.flashes.length ? level.flashes[selectedIndex].y : 0;
		properties.text = "PROPERTIES\n----------------\nType: " + (selectedKind == 0 ? "Player Spawn" : selectedKind == 1 ? "Background Layer" : "Flash Collectible") + "\nX: " + px + "\nY: " + py + "\n\nMusic: " + level.music;

		preview.clear();
		var spawn = new FlxSprite(42 + level.playerX * 0.35, 82 + level.playerY * 0.22).makeGraphic(16, 24, 0xFF55CCFF);
		preview.add(spawn);
		for (i in 0...level.flashes.length)
		{
			var f = level.flashes[i];
			var marker = new FlxSprite(42 + f.x * 0.35, 82 + f.y * 0.22).makeGraphic(12, 12, selectedKind == 2 && selectedIndex == i ? FlxColor.YELLOW : 0xFFFFD700);
			preview.add(marker);
		}
		status.text = "Select objects in the list. Use X/Y controls to position. SAVE BIN writes binary Level.bin.";
	}

	private function loadLevel():Void
	{
		#if ios
		var dialog = new FileDialog();
		dialog.onOpen.add(function(res:Resource) {
			try {
				var bytes:Bytes = cast res;
				//for later public static function loadFromBytes(bytes:Bytes):LevelBin { ... }
				var loaded = LevelBin.loadFromBytes(bytes); 
				
				if (loaded == null) {
					status.text = "Could not parse loaded .bin file.";
					return;
				}
				applyLoadedLevel(loaded);
			} catch (e:Dynamic) {
				status.text = "Binary load failed: " + Std.string(e);
			}
		});
		dialog.onCancel.add(function() {
			status.text = "Load cancelled.";
		});
		dialog.open("bin", null, "Load Level");
		#else
		var loaded = LevelBin.load(levelName);
		if (loaded == null)
		{
			status.text = "Could not load assets/levels/" + levelName + "/Level.bin";
			return;
		}
		applyLoadedLevel(loaded);
		#end
	}

	private function saveLevel():Void
	{
		#if ios
		var dialog = new FileDialog();
		dialog.onSave.add(function(path:String) {
			if (path != null) {
				try {
					var root = buildBinRoot();
					bin.BIN.save(path, bin.BINValue.object(root));
					status.text = "Saved binary to: " + path;
					reloadEditor();
				} catch (e:Dynamic) {
					status.text = "Binary save failed: " + Std.string(e);
				}
			} else {
				status.text = "Save cancelled.";
			}
		});
		dialog.onCancel.add(function() {
			status.text = "Save cancelled.";
		});
		
		var defaultName = level.name + ".bin";
		dialog.save(null, "bin", System.documentsDirectory + "/" + defaultName, "Save Level");
		#else
		try {
			var directory = "assets/levels/" + level.name;
			#if sys
			if (!FileSystem.exists(directory)) FileSystem.createDirectory(directory);
			#end
			var root = buildBinRoot();
			bin.BIN.save(directory + "/Level.bin", bin.BINValue.object(root));
			status.text = "Saved binary " + directory + "/Level.bin";
			reloadEditor();
		} catch (e:Dynamic) {
			status.text = "Binary save failed: " + Std.string(e);
		}
		#end
	}

	private function buildBinRoot():bin.BINObject
	{
		var backgrounds = new bin.BINArray();
		for (item in level.backgrounds)
		{
			var bg = new bin.BINObject();
			bg.set("image", bin.BINValue.string(item.image));
			bg.set("x", bin.BINValue.int(item.x));
			bg.set("y", bin.BINValue.int(item.y));
			bg.set("scrollX", bin.BINValue.int(item.scrollX));
			bg.set("scrollY", bin.BINValue.int(item.scrollY));
			backgrounds.push(bin.BINValue.object(bg));
		}
		
		var flashes = new bin.BINArray();
		for (item in level.flashes)
		{
			var flash = new bin.BINObject();
			flash.set("x", bin.BINValue.int(item.x));
			flash.set("y", bin.BINValue.int(item.y));
			flash.set("value", bin.BINValue.int(item.value));
			flashes.push(bin.BINValue.object(flash));
		}
		
		var player = new bin.BINObject();
		player.set("x", bin.BINValue.int(level.playerX));
		player.set("y", bin.BINValue.int(level.playerY));
		
		var root = new bin.BINObject();
		root.set("name", bin.BINValue.string(level.name));
		root.set("music", bin.BINValue.string(level.music));
		root.set("player", bin.BINValue.object(player));
		root.set("backgrounds", bin.BINValue.array(backgrounds));
		root.set("flashes", bin.BINValue.array(flashes));
		
		return root;
	}

	private function applyLoadedLevel(loaded:LevelBin):Void
	{
		level = loaded;
		levelName = level.name;
		selectedKind = 0;
		selectedIndex = 0;
		refreshUI();
		status.text = "Loaded binary Level.bin and reloaded editor.";
		reloadEditor();
	}

	private function reloadEditor():Void
	{
		FlxG.switchState(new LevelEditorState(levelName));
	}

	private function leaveEditor():Void
	{
		GameState.switchState(new EditorState());
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (controls.BACK) leaveEditor();
		if (controls.GAME_LEFT_P) adjust(-16, 0);
		if (controls.GAME_RIGHT_P) adjust(16, 0);
		if (controls.GAME_UP_P) adjust(0, -16);
		if (controls.GAME_DOWN_P) adjust(0, 16);
		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(playerMarker)) selectedKind = 0;
	}
}
