package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import data.backend.StageData.LevelBin;
import flixel.ui.AUIBox;
import flixel.ui.AUIButton;
import flixel.ui.AUILabel;
import mobile.TouchUtil;
import haxe.io.Bytes;
import lime.utils.Resource;

#if sys
import sys.FileSystem;
#end

#if ios
import lime.ui.FileDialog;
import lime.system.System;
#end

import bin.BIN;
import bin.BINObject;
import bin.BINArray;
import bin.BINValue;

/**
 * Visual level editor.
 * Level data is edited through scene objects and property controls.
 * <LevelName>.bin is read/written as binary using the same BIN API as LevelBin.
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
	private var backgroundMarkers:Array<FlxSprite> = [];
	private var flashMarkers:Array<FlxSprite> = [];
	private var canvasX:Float = 12;
	private var canvasY:Float = 62;
	private var canvasScale:Float = 0.35;

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
		this.canvasX = canvasX;
		this.canvasY = canvasY;
		var canvasW = Std.int(FlxG.width * 0.62);
		var canvasH = FlxG.height - 160;
		var canvas = new FlxSprite(canvasX, canvasY).makeGraphic(canvasW, canvasH, 0xFF182331);
		add(canvas);
		preview = new FlxTypedGroup<FlxSprite>();
		add(preview);

		var inspectorX = canvasX + canvasW + 12;
		var inspectorW = Std.int(FlxG.width - inspectorX - 12);
		var objectsPanel = new AUIBox(inspectorX, canvasY, inspectorW, 138, "OBJECTS");
		add(objectsPanel);
		objectList = new AUILabel(inspectorX + 10, canvasY + 38, inspectorW - 20, "", 11);
		add(objectList);
		var propertiesPanel = new AUIBox(inspectorX, canvasY + 148, inspectorW, 150, "INSPECTOR");
		add(propertiesPanel);
		properties = new AUILabel(inspectorX + 10, canvasY + 184, inspectorW - 20, "", 11, FlxColor.CYAN);
		add(properties);

		status = new FlxText(12, FlxG.height - 62, FlxG.width - 24, "", 12);
		status.setFormat(null, 12, FlxColor.LIME, LEFT);
		add(status);

		addButton(11, "PLAYER", function() { selectedKind = 0; selectedIndex = 0; refreshUI(); });
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
		rebuildPreview();
		refreshUI();

		#if mobile
		addCustomDPad('NONE', 'BACK');
		addCustomDPadCam();
		#end
	}

	private function addButton(slot:Int, label:String, callback:Void->Void):Void
	{
		var columns = 6;
		var row = Std.int((slot - 1) / columns);
		var col = (slot - 1) % columns;
		var w = Std.int((FlxG.width - 16) / columns);
		var x = 8 + col * w;
		var y = FlxG.height - 112 + row * 34;
		var button = new AUIButton(x, y, w - 3, 29, label, callback);
		add(button);
	}
	private function addBackground():Void
	{
		level.backgrounds.push({image: "levels/" + levelName + "/background", x: 0, y: 0, scrollX: 1000, scrollY: 1000});
		selectedKind = 1;
		selectedIndex = level.backgrounds.length - 1;
		rebuildPreview();
		refreshUI();
		status.text = "Background layer added. Select it and adjust its position.";
	}

	private function addFlash():Void
	{
		level.flashes.push({x: level.playerX + 96, y: level.playerY, value: 1});
		selectedKind = 2;
		selectedIndex = level.flashes.length - 1;
		rebuildPreview();
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
		rebuildPreview();
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

		updatePreview();
		status.text = "Select objects in the list. Use X/Y controls to position. SAVE BIN writes binary Level.bin.";
	}

	/** Rebuild only when the level's object collections change. */
	private function rebuildPreview():Void
	{
		if (preview == null || level == null) return;
		preview.clear();
		backgroundMarkers = [];
		flashMarkers = [];

		for (bg in level.backgrounds)
		{
			var layer = new FlxSprite();
			try
			{
				layer.loadGraphic(Paths.image(bg.image));
				layer.scale.set(canvasScale, canvasScale);
				layer.updateHitbox();
			}
			catch (e:Dynamic)
			{
				layer.makeGraphic(36, 24, 0xFF704050);
			}
			preview.add(layer);
			backgroundMarkers.push(layer);
		}

		playerMarker = new FlxSprite().makeGraphic(16, 24, 0xFF55CCFF);
		preview.add(playerMarker);

		for (flash in level.flashes)
		{
			var marker = new FlxSprite().makeGraphic(12, 12, 0xFFFFD700);
			preview.add(marker);
			flashMarkers.push(marker);
		}
		updatePreview();
	}

	/** Update existing marker transforms and selection styling without reallocating sprites. */
	private function updatePreview():Void
	{
		if (level == null || preview == null) return;
		for (i in 0...backgroundMarkers.length)
		{
			var bg = level.backgrounds[i];
			var marker = backgroundMarkers[i];
			marker.setPosition(canvasX + bg.x * canvasScale, canvasY + bg.y * canvasScale);
			marker.alpha = selectedKind == 1 && selectedIndex == i ? 0.95 : 0.45;
		}
		if (playerMarker != null)
			playerMarker.setPosition(canvasX + level.playerX * canvasScale, canvasY + level.playerY * canvasScale);
		for (i in 0...flashMarkers.length)
		{
			var flash = level.flashes[i];
			var marker = flashMarkers[i];
			marker.setPosition(canvasX + flash.x * canvasScale, canvasY + flash.y * canvasScale);
			marker.color = selectedKind == 2 && selectedIndex == i ? FlxColor.YELLOW : 0xFFFFD700;
		}
	}

	private function loadLevel():Void
	{
		#if ios
		var dialog = new FileDialog();
		dialog.onOpen.add(function(res:Resource) {
			try {
				var bytes:Bytes = cast res;
				var binValue = BIN.parse(bytes);
				if (binValue.isObject()) {
					var loaded = loadLevelFromBinValue(binValue.asObject());
					applyLoadedLevel(loaded);
				} else {
					status.text = "Invalid .bin file format.";
				}
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
			status.text = "Could not load assets/levels/" + levelName + "/" + levelName + ".bin";
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
				status.text = "Saved binary to: " + path;
				reloadEditor();
			} else {
				status.text = "Save cancelled.";
			}
		});
		dialog.onCancel.add(function() {
			status.text = "Save cancelled.";
		});
		
		var defaultName = level.name + ".bin";
		var root = buildBinRoot();
		var bytes:Bytes = BIN.write(BINValue.object(root));
		dialog.save(bytes, "bin", System.documentsDirectory + "/" + defaultName, "Save Level");
		#else
		try {
			var directory = "assets/levels/" + level.name;
			#if sys
			if (!FileSystem.exists(directory)) FileSystem.createDirectory(directory);
			#end
			var root = buildBinRoot();
			BIN.save(directory + "/" + level.name + ".bin", BINValue.object(root));
			status.text = "Saved binary " + directory + "/" + level.name + ".bin";
			reloadEditor();
		} catch (e:Dynamic) {
			status.text = "Binary save failed: " + Std.string(e);
		}
		#end
	}

	private function loadLevelFromBinValue(binObj:BINObject):LevelBin
	{
		var loaded = new LevelBin();
		loaded.name = binObj.get("name").asString(levelName);
		loaded.music = binObj.get("music").asString("levels/" + levelName + "/theme");
		loaded.groundY = binObj.get("groundY").asInt(562);
		loaded.worldWidth = binObj.get("worldWidth").asInt(2920);
		
		var playerObj = binObj.get("player").asObject();
		if (playerObj != null) {
			loaded.playerX = playerObj.get("x").asInt(160);
			loaded.playerY = playerObj.get("y").asInt(420);
		}
		
		var bgArray = binObj.get("backgrounds").asArray();
		if (bgArray != null) {
			for (i in 0...bgArray.length) {
				var bgObj = bgArray.get(i).asObject();
				if (bgObj != null) {
					loaded.backgrounds.push({
						image: bgObj.get("image").asString("levels/" + levelName + "/background"),
						x: bgObj.get("x").asInt(0),
						y: bgObj.get("y").asInt(0),
						scrollX: bgObj.get("scrollX").asInt(350),
						scrollY: bgObj.get("scrollY").asInt(350)
					});
				}
			}
		}
		
		var flashArray = binObj.get("flashes").asArray();
		if (flashArray != null) {
			for (i in 0...flashArray.length) {
				var flashObj = flashArray.get(i).asObject();
				if (flashObj != null) {
					loaded.flashes.push({
						x: flashObj.get("x").asInt(420),
						y: flashObj.get("y").asInt(380),
						value: flashObj.get("value").asInt(1)
					});
				}
			}
		}
		
		return loaded;
	}

	private function buildBinRoot():BINObject
	{
		var backgrounds = new BINArray();
		for (item in level.backgrounds)
		{
			var bg = new BINObject();
			bg.set("image", BINValue.string(item.image));
			bg.set("x", BINValue.int(item.x));
			bg.set("y", BINValue.int(item.y));
			bg.set("scrollX", BINValue.int(item.scrollX));
			bg.set("scrollY", BINValue.int(item.scrollY));
			backgrounds.push(BINValue.object(bg));
		}
		
		var flashes = new BINArray();
		for (item in level.flashes)
		{
			var flash = new BINObject();
			flash.set("x", BINValue.int(item.x));
			flash.set("y", BINValue.int(item.y));
			flash.set("value", BINValue.int(item.value));
			flashes.push(BINValue.object(flash));
		}
		
		var player = new BINObject();
		player.set("x", BINValue.int(level.playerX));
		player.set("y", BINValue.int(level.playerY));
		
		var root = new BINObject();
		root.set("name", BINValue.string(level.name));
		root.set("stage", BINValue.string(level.stage));
		root.set("groundY", BINValue.int(level.groundY));
		root.set("worldWidth", BINValue.int(level.worldWidth));
		root.set("music", BINValue.string(level.music));
		root.set("player", BINValue.object(player));
		root.set("backgrounds", BINValue.array(backgrounds));
		root.set("flashes", BINValue.array(flashes));
		
		return root;
	}

	private function applyLoadedLevel(loaded:LevelBin):Void
	{
		level = loaded;
		levelName = level.name;
		selectedKind = 0;
		selectedIndex = 0;
		// Recreate the state so preview markers match the newly loaded object arrays.
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
		if (playerMarker != null && TouchUtil.justPressedOn(playerMarker))
		{
			selectedKind = 0;
			selectedIndex = 0;
			refreshUI();
			return;
		}
		for (i in 0...backgroundMarkers.length)
		{
			if (TouchUtil.justPressedOn(backgroundMarkers[i]))
			{
				selectedKind = 1;
				selectedIndex = i;
				refreshUI();
				return;
			}
		}
		for (i in 0...flashMarkers.length)
		{
			if (TouchUtil.justPressedOn(flashMarkers[i]))
			{
				selectedKind = 2;
				selectedIndex = i;
				refreshUI();
				return;
			}
		}

	}
}
