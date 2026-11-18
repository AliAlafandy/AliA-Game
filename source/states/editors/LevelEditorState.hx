package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import data.backend.StageData.LevelBin;
import data.backend.StageData;
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


/**
 * Visual level editor.
 * Level data is edited through scene objects and property controls.
 * <LevelName>.ellawy is the editable source of truth. Images stay in separate files.
 */
class LevelEditorState extends GameState
{
	private var levelName:String = "NewLevel";
	private var level:LevelBin;
	private var title:FlxText;
	private var status:FlxText;
	private var objectList:FlxText;
	private var properties:FlxText;
	private var preview:FlxTypedGroup<FlxSprite>;
	private var selectedKind:Int = 0;
	private var selectedIndex:Int = 0;
	private var playerMarker:FlxSprite;
	private var groundMarker:FlxSprite;
	private var backgroundMarkers:Array<FlxSprite> = [];
	private var flashMarkers:Array<FlxSprite> = [];
	private var canvasX:Float = 12;
	private var canvasY:Float = 62;
	private var canvasScale:Float = 0.35;

	public function new(?name:String = "NewLevel", ?c:Int = 40, ?r:Int = 24)
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
			level.stage = levelName;
			level.groundY = 520;
			level.worldWidth = 1920;
			level.playerX = 160;
			level.playerY = 460;
			level.music = "";
			// Empty black/gray template. Add image layers when designing a stage.
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
		var canvas = new FlxSprite(canvasX, canvasY).makeGraphic(canvasW, canvasH, FlxColor.BLACK);
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

		status = new FlxText(12, FlxG.height - 20, FlxG.width - 24, "", 10);
		status.setFormat(null, 12, FlxColor.LIME, LEFT);
		add(status);

		addButton(11, "PLAYER", function() { selectedKind = 0; selectedIndex = 0; refreshUI(); });
		addButton(1, "BACK", leaveEditor);
		addButton(2, "ADD BG", addBackground);
		addButton(3, "ADD ITEM", addFlash);
		addButton(4, "REMOVE", removeSelected);
		addButton(5, "X-", function() adjust(-16, 0));
		addButton(6, "X+", function() adjust(16, 0));
		addButton(7, "Y-", function() adjust(0, -16));
		addButton(8, "Y+", function() adjust(0, 16));
		addButton(9, "SAVE ELLAWY", saveLevel);
		addButton(10, "LOAD ELLAWY", loadLevel);
		addButton(12, "CAM +", function() { level.cameraZoom += 100; refreshUI(); });
		addButton(13, "CAM -", function() { level.cameraZoom = Std.int(Math.max(100, level.cameraZoom - 100)); refreshUI(); });
		addButton(14, "WIDTH +", function() { level.worldWidth += 320; refreshUI(); });
		addButton(15, "WIDTH -", function() { level.worldWidth = Std.int(Math.max(640, level.worldWidth - 320)); refreshUI(); });
		addButton(16, "DZ +", function() { level.cameraDeadzoneWidth += 20; level.cameraDeadzoneHeight += 20; refreshUI(); });
		addButton(17, "DZ -", function() { level.cameraDeadzoneWidth = Std.int(Math.max(40, level.cameraDeadzoneWidth - 20)); level.cameraDeadzoneHeight = Std.int(Math.max(40, level.cameraDeadzoneHeight - 20)); refreshUI(); });
		addButton(18, "GROUND +", function() { level.groundY += 16; refreshUI(); });
		addButton(19, "GROUND -", function() { level.groundY = Std.int(Math.max(0, level.groundY - 16)); refreshUI(); });
		addButton(20, "TOGGLE GROUND", toggleGroundLayer);
		addButton(21, "SCALE +", function() { adjustLayerScale(100); });
		addButton(22, "SCALE -", function() { adjustLayerScale(-100); });
		rebuildPreview();
		refreshUI();

		#if mobile
		addCustomDPad('NONE', 'BACK');
		addCustomDPadCam();
		#end
	}

	private function addButton(slot:Int, label:String, callback:Void->Void):Void
	{
		var columns = 8;
		var row = Std.int((slot - 1) / columns);
		var col = (slot - 1) % columns;
		var w = Std.int((FlxG.width - 16) / columns);
		var x = 8 + col * w;
		var y = FlxG.height - 132 + row * 34;
		var button = new AUIButton(x, y, w - 3, 29, label, callback);
		add(button);
	}
	private function addBackground():Void
	{
		level.backgrounds.push({image: "levels/" + levelName + "/background", x: 0, y: level.groundY, scrollX: 1000, scrollY: 1000, scaleX: 1000, scaleY: 1000, isGround: false, isMultiple: false, multipleCount: 0});
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

	private function toggleGroundLayer():Void
	{
		if (selectedKind != 1 || selectedIndex < 0 || selectedIndex >= level.backgrounds.length)
		{
			status.text = "Select a background layer before toggling its ground collider.";
			return;
		}
		var selected = level.backgrounds[selectedIndex];
		selected.isGround = !selected.isGround;
		if (selected.isGround)
			for (i in 0...level.backgrounds.length)
				if (i != selectedIndex) level.backgrounds[i].isGround = false;
		refreshUI();
		status.text = selected.isGround ? "This layer is the level's only ground collider." : "Ground collider disabled for this layer.";
	}

	private function adjustLayerScale(amount:Int):Void
	{
		if (selectedKind != 1 || selectedIndex < 0 || selectedIndex >= level.backgrounds.length)
		{
			status.text = "Select a background layer to scale it.";
			return;
		}
		var layer = level.backgrounds[selectedIndex];
		layer.scaleX = Std.int(Math.max(100, Math.min(5000, layer.scaleX + amount)));
		layer.scaleY = Std.int(Math.max(100, Math.min(5000, layer.scaleY + amount)));
		updatePreview();
		refreshUI();
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
			case 0: level.playerX += dx; if (level.playerY < 0) level.playerY = level.groundY - 24; level.playerY += dy;
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
		lines.push("ITEMS (" + level.flashes.length + ")");
		for (i in 0...level.flashes.length) lines.push("  FLASH " + i + (selectedKind == 2 && selectedIndex == i ? "  <" : ""));
		objectList.text = lines.join("\n");

		var px = selectedKind == 0 ? level.playerX : selectedKind == 1 && selectedIndex < level.backgrounds.length ? level.backgrounds[selectedIndex].x : selectedKind == 2 && selectedIndex < level.flashes.length ? level.flashes[selectedIndex].x : 0;
		var py = selectedKind == 0 ? (level.playerY >= 0 ? level.playerY : level.groundY - 24) : selectedKind == 1 && selectedIndex < level.backgrounds.length ? level.backgrounds[selectedIndex].y : selectedKind == 2 && selectedIndex < level.flashes.length ? level.flashes[selectedIndex].y : 0;
		var layerInfo = selectedKind == 1 && selectedIndex >= 0 && selectedIndex < level.backgrounds.length ? "\nScale: " + (level.backgrounds[selectedIndex].scaleX / 1000) + " x " + (level.backgrounds[selectedIndex].scaleY / 1000) + "\nGround collider: " + (level.backgrounds[selectedIndex].isGround ? "ON" : "OFF") : "";
		properties.text = "PROPERTIES\n----------------\nType: " + (selectedKind == 0 ? "Player Spawn" : selectedKind == 1 ? "Background Layer" : "Flash Item") + "\nX: " + px + "\nY: " + py + layerInfo + "\n\nWorld Width: " + level.worldWidth + "\nGround Y: " + level.groundY + "\nCamera Zoom: " + (level.cameraZoom / 1000) + "\nDeadzone: " + level.cameraDeadzoneWidth + " x " + level.cameraDeadzoneHeight + "\nMusic: " + level.music;

		updatePreview();
		status.text = "Select objects in the list. Use X/Y controls to position. SAVE ELLAWY writes "+ levelName +".ellawy.";
	}

	/** Rebuild only when the level's object collections change. */
	private function rebuildPreview():Void
	{
		if (preview == null || level == null) return;
		preview.clear();
		backgroundMarkers = [];
		flashMarkers = [];
		groundMarker = null;
		if (level.backgrounds.length == 0)
		{
			groundMarker = new FlxSprite(canvasX, canvasY + level.groundY * canvasScale);
			groundMarker.makeGraphic(Std.int(Math.min(FlxG.width * 0.62, level.worldWidth * canvasScale)), 12, 0xFF777777);
			preview.add(groundMarker);
		}
		for (bg in level.backgrounds)
		{
			var layer = new FlxSprite();
			try
			{
				var imageKey = bg.image;
				if (imageKey.toLowerCase().endsWith(".png")) imageKey = imageKey.substr(0, imageKey.length - 4);
				layer.loadGraphic(Paths.image(imageKey));
				layer.scale.set(canvasScale * bg.scaleX / 1000, canvasScale * bg.scaleY / 1000);
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
		if (groundMarker != null)
		{
			groundMarker.y = canvasY + level.groundY * canvasScale;
			groundMarker.makeGraphic(Std.int(Math.min(FlxG.width * 0.62, level.worldWidth * canvasScale)), 12, 0xFF777777);
		}
		for (i in 0...backgroundMarkers.length)
		{
			var bg = level.backgrounds[i];
			var marker = backgroundMarkers[i];
			marker.setPosition(canvasX + bg.x * canvasScale, canvasY + bg.y * canvasScale);
			marker.scale.set(canvasScale * bg.scaleX / 1000, canvasScale * bg.scaleY / 1000);
			marker.updateHitbox();
			marker.alpha = selectedKind == 1 && selectedIndex == i ? 0.95 : 0.45;
		}
		if (playerMarker != null)
			playerMarker.setPosition(canvasX + level.playerX * canvasScale, canvasY + (level.playerY >= 0 ? level.playerY : level.groundY - 24) * canvasScale);
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
			var loaded = StageData.parseEllawyLevel(levelName, (cast res:Bytes).toString());
			if (loaded != null) applyLoadedLevel(loaded); else status.text = "Invalid .ellawy level file.";
		});
		dialog.onCancel.add(function() status.text = "Load cancelled.");
		dialog.open("ellawy", null, "Load Ellawy Level");
		#else
		var loaded = LevelBin.load(levelName);
		if (loaded == null) { status.text = "Could not load .ellawy level: assets/levels/" + levelName + "/" + levelName + ".ellawy"; return; }
		applyLoadedLevel(loaded);
		#end
	}

	private function quoteEllawy(value:String):String
	{
		return haxe.Json.stringify(value == null ? "" : value);
	}

	private function buildEllawySource():String
	{
		var out = new StringBuf();
		out.add("local level = {\n");
		out.add("  name: " + quoteEllawy(level.name) + ",\n");
		out.add("  stage: " + quoteEllawy(level.stage) + ",\n");
		out.add("  worldWidth: " + level.worldWidth + ",\n");
		out.add("  groundY: " + level.groundY + ",\n");
		out.add("  music: " + quoteEllawy(level.music) + ",\n");
		out.add("  cameraZoom: " + level.cameraZoom + ",\n");
		out.add("  cameraDeadzoneWidth: " + level.cameraDeadzoneWidth + ",\n");
		out.add("  cameraDeadzoneHeight: " + level.cameraDeadzoneHeight + ",\n");
		out.add("  nextStage: " + quoteEllawy(level.nextStage) + ",\n");
		out.add("  player: { x: " + level.playerX + ", y: " + level.playerY + " },\n");
		out.add("  backgrounds: [\n");
		for (i in 0...level.backgrounds.length)
		{
			var item = level.backgrounds[i];
			out.add("    { image: " + quoteEllawy(item.image) + ", x: " + item.x + ", y: " + item.y + ", scrollX: " + item.scrollX + ", scrollY: " + item.scrollY + ", scaleX: " + item.scaleX + ", scaleY: " + item.scaleY + ", isGround: " + (item.isGround ? "true" : "false") + ", isMultiple: " + (item.isMultiple ? "true" : "false") + ", multipleCount: " + item.multipleCount + " }");
			out.add(i + 1 < level.backgrounds.length ? ",\n" : "\n");
		}
		out.add("  ],\n  items: [\n");
		for (i in 0...level.flashes.length)
		{
			var item = level.flashes[i];
			out.add("    { x: " + item.x + ", y: " + item.y + ", value: " + item.value + " }");
			out.add(i + 1 < level.flashes.length ? ",\n" : "\n");
		}
		out.add("  ]\n}\n");
		return out.toString();
	}

	private function saveLevel():Void
	{
		var source = buildEllawySource();
		#if ios
		var dialog = new FileDialog();
		dialog.onSave.add(function(path:String) {
			if (path != null) { status.text = "Saved Ellawy level: " + path; reloadEditor(); }
			else status.text = "Save cancelled.";
		});
		dialog.onCancel.add(function() status.text = "Save cancelled.");
		dialog.save(Bytes.ofString(source), "ellawy", System.documentsDirectory + "/" + level.name + ".ellawy", "Save Level");
		#else
		try
		{
			var directory = "assets/levels/" + level.name;
			#if sys
			if (!FileSystem.exists(directory)) FileSystem.createDirectory(directory);
			var outputPath = directory + "/" + level.name + ".ellawy";
			File.saveContent(outputPath, source);
			status.text = "Saved Ellawy level: " + outputPath;
			reloadEditor();
			#else
			status.text = "This platform requires the level export dialog.";
			#end
		}
		catch (e:Dynamic) status.text = "Ellawy save failed: " + Std.string(e);
		#end
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
		if (playerMarker != null && ((FlxG.mouse.justPressed && FlxG.mouse.overlaps(playerMarker)) || TouchUtil.justPressedOn(playerMarker)))
		{
			selectedKind = 0;
			selectedIndex = 0;
			refreshUI();
			return;
		}
		for (i in 0...backgroundMarkers.length)
		{
			if ((FlxG.mouse.justPressed && FlxG.mouse.overlaps(backgroundMarkers[i])) || TouchUtil.justPressedOn(backgroundMarkers[i]))
			{
				selectedKind = 1;
				selectedIndex = i;
				refreshUI();
				return;
			}
		}
		for (i in 0...flashMarkers.length)
		{
			if ((FlxG.mouse.justPressed && FlxG.mouse.overlaps(flashMarkers[i])) || TouchUtil.justPressedOn(flashMarkers[i]))
			{
				selectedKind = 2;
				selectedIndex = i;
				refreshUI();
				return;
			}
		}

	}
}
