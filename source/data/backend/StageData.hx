package data.backend;

import bin.BIN;
import bin.BINValue;
import bin.BINObject;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.utils.Assets;
import data.scripts.GameEllawyScript;
import haxe.io.Bytes;

#if sys
import sys.FileSystem;
import sys.io.File;
#end
using StringTools;

/**
 * Stage and level asset access.
 *
 * Each level uses one Ellawy source file:
 * assets/levels/<LevelName>/<LevelName>.ellawy
 * External PNGs are referenced by path and are never embedded in level files.
 * Legacy .bin level documents are read only when no .ellawy file exists.
 * Act<act>.bin remains legacy act metadata.
 */
class StageData
{
	public static var forceNextDirectory:String = null;
	public static var currentAct:Int = 1;
	public static var groundSprite:FlxSprite = null;
	public static var floorCollider:FlxSprite = null;
	public static var hasPackedLevelAssets:Bool = false;
	public static var hasLoadedLevelImages:Bool = false;
	public static var loadedFromEllawy:Bool = false;

	public static function loadDirectory(stageName:String, act:Int = 1):Void
	{
		currentAct = act;
		var stageData:BINValue = getStageFile(stageName, act);

		if (stageData == null || !stageData.isObject())
		{
			forceNextDirectory = "";
			return;
		}

		var stageObject:BINObject = stageData.asObject();
		var directoryValue:BINValue = stageObject.get("directory");
		if (directoryValue != null)
		{
			var directory = directoryValue.asString("");
			if (directory != null && directory.length > 0)
			{
				forceNextDirectory = directory;
				return;
			}
		}

		forceNextDirectory = (stageName + act).toLowerCase();
	}

	public static function getLevelAssetPath(stageName:String, act:Int, fileName:String):String
	{
		var relative = "levels/" + stageName + "/" + fileName;
		#if MODS_ALLOWED
		var modPath = Paths.modFolders(relative);
		#if sys
		if (FileSystem.exists(modPath)) return modPath;
		#end
		#end
		return Paths.getSharedPath(relative);
	}

	/** Stage progression order; a level's nextStage in its BIN can override this. */
	public static function getNextStageName(stageName:String):String
	{
		var order = ["ATown", "Neon", "Nature", "Wet", "Water", "Desert", "Mountain", "Fire", "Air", "Space", "Doom", "Flash", "Special", "Test"];
		var index = order.indexOf(stageName);
		if (index < 0 || index + 1 >= order.length) return "";
		return order[index + 1];
	}
	private static inline function field(data:Dynamic, name:String, fallback:Dynamic):Dynamic
	{
		if (data == null || !Reflect.hasField(data, name)) return fallback;
		var value = Reflect.field(data, name);
		return value == null ? fallback : value;
	}

	private static function loadEllawyLevel(stage:String):LevelBin
	{
		var relative = "levels/" + stage + "/" + stage + ".ellawy";
		var path = StageData.getLevelAssetPath(stage, StageData.currentAct, stage + ".ellawy");
		var source:String = null;
		try
		{
			#if sys
			if (FileSystem.exists(path)) source = File.getContent(path);
			#end
			if (source == null && Assets.exists(path)) source = Assets.getText(path);
			if (source == null) return null;
			return parseEllawyLevel(stage, source);
		}
		catch (e:Dynamic) { trace("[StageData] Ellawy level error in " + relative + ": " + Std.string(e)); }
		return null;
	}

	public static function parseEllawyLevel(stage:String, source:String):LevelBin
	{
		try
		{
			var script = new GameEllawyScript("levels/" + stage + "/" + stage + ".ellawy", source);
			var raw:Dynamic = script.get("level");
			if (raw == null) raw = script.call("onLoadLevel");
			if (raw == null) throw "Define local level = {...} in the Ellawy file.";
			var result = new LevelBin();
			result.name = Std.string(field(raw, "name", stage));
			result.stage = Std.string(field(raw, "stage", stage));
			result.worldWidth = Std.int(field(raw, "worldWidth", 1920));
			result.groundY = Std.int(field(raw, "groundY", 520));
			result.music = Std.string(field(raw, "music", ""));
			result.cameraZoom = Std.int(field(raw, "cameraZoom", 1000));
			result.cameraDeadzoneWidth = Std.int(field(raw, "cameraDeadzoneWidth", 200));
			result.cameraDeadzoneHeight = Std.int(field(raw, "cameraDeadzoneHeight", 200));
			result.nextStage = Std.string(field(raw, "nextStage", ""));
			var player = field(raw, "player", null);
			result.playerX = Std.int(field(player, "x", 160));
			result.playerY = Std.int(field(player, "y", -1));
			var backgrounds:Array<Dynamic> = cast field(raw, "backgrounds", []);
			if (backgrounds != null) for (item in backgrounds)
				result.backgrounds.push({image:Std.string(field(item, "image", "")), x:Std.int(field(item, "x", 0)), y:Std.int(field(item, "y", 0)), scrollX:Std.int(field(item, "scrollX", 1000)), scrollY:Std.int(field(item, "scrollY", 1000)), scaleX:Std.int(field(item, "scaleX", 1000)), scaleY:Std.int(field(item, "scaleY", 1000)), isGround:field(item, "isGround", false) == true});
			var items:Array<Dynamic> = cast field(raw, "items", []);
			if (items != null) for (item in items) result.flashes.push({x:Std.int(field(item, "x", 0)), y:Std.int(field(item, "y", 0)), value:Std.int(field(item, "value", 1))});
			return result;
		}
		catch (e:Dynamic) { trace("[StageData] Could not parse Ellawy level " + stage + ": " + Std.string(e)); }
		return null;
	}
	public static function getStageFile(stageName:String, act:Int):BINValue
	{
		var relative = "levels/" + stageName + "/Act" + act + ".bin";
		var path = Paths.getSharedPath(relative);

		try
		{
			#if sys
			#if MODS_ALLOWED
			var modPath = Paths.modFolders(relative);
			if (FileSystem.exists(modPath)) return BIN.read(modPath);
			#end
			if (FileSystem.exists(path)) return BIN.read(path);
			#end
			if (Assets.exists(path))
			{
				var bytes = Assets.getBytes(path);
				if (bytes != null) return BIN.parse(bytes);
			}
		}
		catch (e:Dynamic)
		{
			trace("[StageData] Failed to load " + relative + ": " + Std.string(e));
		}
		return null;
	}

	/** Load external image files referenced by the Ellawy level. */
	public static function addLevelImages(stageName:String, group:FlxTypedGroup<FlxSprite>, levelData:LevelBin = null):FlxSprite
	{
		groundSprite = null; floorCollider = null; hasPackedLevelAssets = false; hasLoadedLevelImages = false;
		if (group == null || levelData == null) return null;
		for (data in levelData.backgrounds)
		{
			var imageKey = data.image;
			if (imageKey == null || imageKey.length == 0) continue;
			if (imageKey.toLowerCase().endsWith(".png")) imageKey = imageKey.substr(0, imageKey.length - 4);
			try
			{
				var sprite = new FlxSprite(data.x, data.y);
				sprite.loadGraphic(Paths.image(imageKey));
				sprite.scrollFactor.set(data.scrollX / 1000, data.scrollY / 1000);
				sprite.scale.set(Math.max(0.01, data.scaleX / 1000), Math.max(0.01, data.scaleY / 1000));
				sprite.updateHitbox();
				sprite.allowCollisions = flixel.util.FlxDirectionFlags.NONE;
				group.add(sprite);
				hasLoadedLevelImages = true;
				if (data.isGround && floorCollider == null)
				{
					groundSprite = sprite;
					floorCollider = new FlxSprite(sprite.x, sprite.y);
					floorCollider.makeGraphic(1, 12, FlxColor.TRANSPARENT);
					floorCollider.setSize(Std.int(Math.max(1, sprite.width)), 12);
					floorCollider.visible = false; floorCollider.immovable = true;
					floorCollider.allowCollisions = flixel.util.FlxDirectionFlags.UP;
				}
			}
			catch (e:Dynamic) trace("[StageData] Missing level image " + imageKey + ": " + Std.string(e));
		}
		return floorCollider;
	}

}


typedef LevelBackgroundData =
{
	var image:String;
	var x:Int;
	var y:Int;
	var scrollX:Int;
	var scrollY:Int;
	var scaleX:Int;
	var scaleY:Int;
	var isGround:Bool;
}

typedef LevelFlashData =
{
	var x:Int;
	var y:Int;
	var value:Int;
}


class LevelBin
{
	public function new() {}

	public var name:String = "NewLevel";
	public var stage:String = "";
	public var groundY:Int = 520;
	public var worldWidth:Int = 1920;
	public var music:String = "";
	public var playerX:Int = 500;
	public var playerY:Int = -1;
	public var cameraZoom:Int = 1000;
	public var cameraDeadzoneWidth:Int = 200;
	public var cameraDeadzoneHeight:Int = 200;
	public var nextStage:String = "";
	public var backgrounds:Array<LevelBackgroundData> = [];
	public var flashes:Array<LevelFlashData> = [];

	public static function load(stage:String):LevelBin
	{
		var scriptLevel = StageData.loadEllawyLevel(stage);
		if (scriptLevel != null) { StageData.loadedFromEllawy = true; return scriptLevel; }
		StageData.loadedFromEllawy = false;
		// Legacy fallback: read old BIN-authored levels only when no .ellawy level exists.
		var relative = "levels/" + stage + "/" + stage + ".bin";
		var path = StageData.getLevelAssetPath(stage, StageData.currentAct, stage + ".bin");
		var result = new LevelBin();
		result.name = stage;
		result.stage = stage;
		try
		{
			var bytes:Bytes = null;
			#if sys
			if (FileSystem.exists(path)) bytes = File.getBytes(path);
			#end
			if (bytes == null && Assets.exists(path)) bytes = Assets.getBytes(path);
			if (bytes == null) { trace("[LevelBin] Missing " + relative); return null; }
			// Legacy .bin contains only the old binary level document.
			var parsed = BIN.parse(bytes);
			if (parsed == null || !parsed.isObject()) throw "Unsupported stage BIN format";
			var root = parsed.asObject();
			result.name = root.get("name").asString(stage);
			result.stage = root.get("stage").asString(stage);
			result.worldWidth = root.get("worldWidth").asInt(result.worldWidth);
			result.groundY = root.get("groundY").asInt(result.groundY);
			if (result.worldWidth < 640) result.worldWidth = 1920;
			result.music = root.get("music").asString("");
			result.cameraZoom = root.get("cameraZoom").asInt(1000);
			result.cameraDeadzoneWidth = root.get("cameraDeadzoneWidth").asInt(200);
			result.cameraDeadzoneHeight = root.get("cameraDeadzoneHeight").asInt(200);
			result.nextStage = root.get("nextStage").asString("");
			var player = root.get("player").asObject();
			if (player != null) { result.playerX = player.get("x").asInt(result.playerX); result.playerY = player.get("y").asInt(result.playerY); }
			var backgroundArray = root.get("backgrounds").asArray();
			if (backgroundArray != null) for (i in 0...backgroundArray.length)
			{
				var item = backgroundArray.get(i).asObject();
				if (item == null) continue;
				var image = item.get("image").asString("");
				if (image == "") continue;
				result.backgrounds.push({image:image, x:item.get("x").asInt(0), y:item.get("y").asInt(0), scrollX:item.get("scrollX").asInt(1000), scrollY:item.get("scrollY").asInt(1000), scaleX:item.get("scaleX").asInt(1000), scaleY:item.get("scaleY").asInt(1000), isGround:item.get("isGround").asInt(0) != 0});
			}
			var flashArray = root.get("flashes").asArray();
			if (flashArray != null) for (i in 0...flashArray.length)
			{
				var item = flashArray.get(i).asObject();
				if (item == null) continue;
				result.flashes.push({x:item.get("x").asInt(0), y:item.get("y").asInt(0), value:item.get("value").asInt(1)});
			}
			return result;
		}
		catch (e:Dynamic) { trace("[LevelBin] Failed to parse " + relative + ": " + Std.string(e)); return null; }
	}

	public function addBackgrounds(group:FlxTypedGroup<FlxSprite>):Void
	{
		if (group == null) return;
		for (data in backgrounds)
		{
			var sprite = new FlxSprite(data.x, data.y);
			var imageKey = data.image;
			if (imageKey.toLowerCase().endsWith(".png")) imageKey = imageKey.substr(0, imageKey.length - 4);
			sprite.loadGraphic(Paths.image(imageKey));
			sprite.scrollFactor.set(data.scrollX / 1000, data.scrollY / 1000);
			sprite.scale.set(Math.max(0.01, data.scaleX / 1000), Math.max(0.01, data.scaleY / 1000));
			sprite.updateHitbox();
			sprite.allowCollisions = flixel.util.FlxDirectionFlags.NONE;
			group.add(sprite);
			StageData.hasLoadedLevelImages = true;
		}
	}

	public function addFlashes(group:FlxTypedGroup<FlxSprite>):Void
	{
		if (group == null) return;
		for (data in flashes)
		{
			var sprite = new FlxSprite(data.x, data.y);
			sprite.makeGraphic(18, 18, 0xFFFFD700);
			sprite.ID = data.value;
			group.add(sprite);
		}
	}
}

