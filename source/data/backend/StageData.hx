package data.backend;

import bin.BIN;
import bin.BINValue;
import bin.BINObject;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.display.BitmapData;
import openfl.utils.Assets;
import haxe.crypto.Base64;
import haxe.io.Bytes;

#if sys
import sys.FileSystem;
import sys.io.File;
#end
using StringTools;

/**
 * Stage and level asset access.
 *
 * Each level uses one BIN data file:
 * assets/levels/<LevelName>/<LevelName>.bin
 * Each stage BIN may be a packed image archive or a binary LevelBin document.
 * PlayState loads visuals from this file, never generated scenery.
 * Act<act>.bin remains separate stage metadata.
 */
class StageData
{
	public static var forceNextDirectory:String = null;
	public static var currentAct:Int = 1;
	public static var groundSprite:FlxSprite = null;
	public static var floorCollider:FlxSprite = null;
	public static var hasPackedLevelAssets:Bool = false;
	private static var decodedImages:Map<String, BitmapData> = new Map();

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

	/** Load all image layers for a level from its single packed .bin file. */
	/** Load packed artwork and apply per-image position, scale and ground metadata from the level BIN. */
	public static function addLevelImages(stageName:String, group:FlxTypedGroup<FlxSprite>, levelData:LevelBin = null):FlxSprite
	{
		groundSprite = null;
		floorCollider = null;
		hasPackedLevelAssets = false;
		if (group == null) return null;

		var relative = "levels/" + stageName + "/" + stageName + ".bin";
		var path = getLevelAssetPath(stageName, currentAct, stageName + ".bin");
		var content:String = null;

		try
		{
			#if sys
			if (FileSystem.exists(path)) content = File.getContent(path);
			#end
			if (content == null && Assets.exists(path)) content = Assets.getBytes(path).toString();
			if (content == null)
			{
				trace("[StageData] Packed level images not found: " + relative);
				return null;
			}

			var lines = content.split("\n");
			if (lines.length == 0 || lines[0].trim() != "LEVELASSETS|1")
				throw "Invalid packed level image archive header";
			hasPackedLevelAssets = true;

			for (lineIndex in 1...lines.length)
			{
				var line = lines[lineIndex].trim();
				if (line.length == 0 || line.startsWith("LEVELDATA|")) continue;
				var separator = line.indexOf("|");
				if (separator <= 0) continue;
				var imageName = line.substr(0, separator);
				var encoded = line.substr(separator + 1);
				if (!imageName.toLowerCase().endsWith(".png")) continue;
				var bitmap = BitmapData.fromBytes(Base64.decode(encoded));
				if (bitmap == null) continue;
				var cacheKey = stageName + "/" + imageName;
				if (decodedImages.exists(cacheKey)) decodedImages.get(cacheKey).dispose();
				decodedImages.set(cacheKey, bitmap);
			}

			var order = ["sky.png", "sun.png", "clouds.png", "buildings.png", "sidewalk.png", "street.png"];
			var groundCreated = false;
			for (imageName in order)
			{
				var bitmap = decodedImages.get(stageName + "/" + imageName);
				if (bitmap == null) continue;

				var layerData:LevelBackgroundData = null;
				if (levelData != null)
				{
					for (candidate in levelData.backgrounds)
					{
						var candidateName = candidate.image.split("/").pop();
						if (candidateName == imageName) { layerData = candidate; break; }
					}
				}

				var sprite = new FlxSprite();
				sprite.loadGraphic(bitmap);
				sprite.x = 0;
				switch (imageName)
				{
					case "sky.png": sprite.y = 0; sprite.scrollFactor.set(0.05, 0.05);
					case "sun.png": sprite.y = 60; sprite.scrollFactor.set(0.25, 0.25);
					case "clouds.png": sprite.y = 40; sprite.scrollFactor.set(0.25, 0.25);
					case "buildings.png": sprite.y = 150; sprite.scrollFactor.set(0.25, 0.25);
					case "sidewalk.png": sprite.y = FlxG.height - bitmap.height - 48; sprite.scrollFactor.set(0.25, 0.25);
					case "street.png": sprite.y = FlxG.height - bitmap.height; sprite.scrollFactor.set(1, 1);
				}

				if (layerData != null)
				{
					sprite.x = layerData.x;
					sprite.y = layerData.y;
					sprite.scrollFactor.set(layerData.scrollX / 1000, layerData.scrollY / 1000);
					sprite.scale.set(Math.max(0.01, layerData.scaleX / 1000), Math.max(0.01, layerData.scaleY / 1000));
				}
				sprite.updateHitbox();
				// Artwork is never a collider. Only the explicit BIN ground option creates one.
				sprite.allowCollisions = flixel.util.FlxDirectionFlags.NONE;
				group.add(sprite);

				if (layerData != null && layerData.isGround && !groundCreated)
				{
					groundCreated = true;
					groundSprite = sprite;
					var groundWidth = sprite.width;
					if (imageName == "street.png" && levelData != null)
						groundWidth = Math.max(groundWidth, levelData.worldWidth);
					floorCollider = new FlxSprite(sprite.x, sprite.y);
					floorCollider.makeGraphic(1, 12, FlxColor.TRANSPARENT);
					floorCollider.setSize(Std.int(Math.max(1, groundWidth)), 12);
					floorCollider.visible = false;
					floorCollider.immovable = true;
					floorCollider.allowCollisions = flixel.util.FlxDirectionFlags.UP;
				}
			}
		}
		catch (e:Dynamic)
		{
			hasPackedLevelAssets = false;
			trace("[StageData] Failed to load " + relative + ": " + Std.string(e));
		}
		return floorCollider;
	}

	public static function getLevelImage(stageName:String, imageName:String):BitmapData
	{
		return decodedImages.get(stageName + "/" + imageName);
	}

	public static function clearLevelImages(stageName:String):Void
	{
		for (key in decodedImages.keys())
		{
			if (key.startsWith(stageName + "/"))
			{
				var bitmap = decodedImages.get(key);
				if (bitmap != null) bitmap.dispose();
				decodedImages.remove(key);
			}
		}
		groundSprite = null;
		floorCollider = null;
		hasPackedLevelAssets = false;
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
			// Keep packed artwork and embed editable level data in the same BIN.
			var archiveLines = bytes.toString().split("\n");
			if (archiveLines.length > 0 && archiveLines[0].trim() == "LEVELASSETS|1")
			{
				var levelDataBytes:Bytes = null;
				for (line in archiveLines)
				{
					if (line.startsWith("LEVELDATA|"))
					{
						levelDataBytes = Base64.decode(line.substr("LEVELDATA|".length));
						break;
					}
				}
				if (levelDataBytes == null) return result;
				bytes = levelDataBytes;
			}
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
			var packedImage = StageData.getLevelImage(stage, data.image);
			if (packedImage != null) sprite.loadGraphic(packedImage);
			else sprite.loadGraphic(Paths.image(data.image));
			sprite.scrollFactor.set(data.scrollX / 1000, data.scrollY / 1000);
			group.add(sprite);
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

