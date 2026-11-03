package data.backend;

import bin.BIN;
import bin.BINValue;
import bin.BINObject;
import flixel.FlxG;
import flixel.FlxSprite;
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
 * LevelBin reads/writes the stage configuration and image layers reference
 * normal image assets. Act<act>.bin remains separate stage metadata.
 */
class StageData
{
	public static var forceNextDirectory:String = null;
	public static var currentAct:Int = 1;
	public static var groundSprite:FlxSprite = null;
	public static var floorCollider:FlxSprite = null;
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
	public static function addLevelImages(stageName:String, group:FlxTypedGroup<FlxSprite>):FlxSprite
	{
		groundSprite = null;
		floorCollider = null;
		if (group == null) return null;

		var relative = "levels/" + stageName + "/" + stageName + ".bin";
		var path = getLevelAssetPath(stageName, currentAct, stageName + ".bin");
		var content:String = null;

		try
		{
			#if sys
			if (FileSystem.exists(path)) content = File.getContent(path);
			#end
			if (content == null && Assets.exists(path)) content = Assets.getText(path);
			if (content == null)
			{
				trace("[StageData] Packed level images not found: " + relative);
				return null;
			}

			var lines = content.split("\n");
			if (lines.length == 0 || lines[0].trim() != "LEVELASSETS|1")
				throw "Invalid packed level image archive header";

			for (lineIndex in 1...lines.length)
			{
				var line = lines[lineIndex].trim();
				if (line.length == 0) continue;
				var separator = line.indexOf("|");
				if (separator <= 0) continue;

				var imageName = line.substr(0, separator);
				var encoded = line.substr(separator + 1);
				if (!imageName.toLowerCase().endsWith(".png")) continue;

				var bitmap = BitmapData.fromBytes(Base64.decode(encoded));
				if (bitmap == null) continue;
				if (decodedImages.exists(stageName + "/" + imageName))
					decodedImages.get(stageName + "/" + imageName).dispose();
				decodedImages.set(stageName + "/" + imageName, bitmap);
			}

			var order = ["sky.png", "sun.png", "clouds.png", "buildings.png", "sidewalk.png", "street.png"];
			for (imageName in order)
			{
				var bitmap = decodedImages.get(stageName + "/" + imageName);
				if (bitmap == null) continue;

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
					case "street.png":
						sprite.y = FlxG.height - bitmap.height;
						sprite.scrollFactor.set(0.25, 0.25);
						// The road image is also the physical floor.
						groundSprite = sprite;
						floorCollider = new FlxSprite(0, sprite.y);
						floorCollider.makeGraphic(1, 12, 0x00000000);
						floorCollider.updateHitbox();
						floorCollider.setSize(bitmap.width * 8, 12);
						floorCollider.visible = false;
						floorCollider.immovable = true;
						floorCollider.allowCollisions = flixel.util.FlxDirectionFlags.UP;
						for (tile in 1...8)
						{
							var roadTile = new FlxSprite(tile * bitmap.width, sprite.y);
							roadTile.loadGraphic(bitmap);
							roadTile.scrollFactor.set(1, 1);
							group.add(roadTile);
						}
				}
				group.add(sprite);
			}
		}
		catch (e:Dynamic)
		{
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
	}
}


typedef LevelBackgroundData =
{
	var image:String;
	var x:Int;
	var y:Int;
	var scrollX:Int;
	var scrollY:Int;
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
	public var backgrounds:Array<LevelBackgroundData> = [];
	public var flashes:Array<LevelFlashData> = [];

	public static function load(stage:String):LevelBin
	{
		var relative = "levels/" + stage + "/" + stage + ".bin";
		var path = StageData.getLevelAssetPath(stage, StageData.currentAct, stage + ".bin");
		var parsed:BINValue = null;

		try
		{
			#if sys
			#if MODS_ALLOWED
			if (FileSystem.exists(path))
				parsed = BIN.read(path);
			#end
			if (parsed == null && FileSystem.exists(path))
				parsed = BIN.read(path);
			#end
			if (parsed == null && Assets.exists(path))
			{
				var bytes = Assets.getBytes(path);
				if (bytes != null) parsed = BIN.parse(bytes);
			}

			if (parsed == null || !parsed.isObject())
			{
				trace("[LevelBin] Missing or invalid " + relative);
				return null;
			}

			var root = parsed.asObject();
			var result = new LevelBin();
			result.name = root.get("name").asString(stage);
			result.stage = stage;
			result.worldWidth = root.get("worldWidth").asInt(result.worldWidth);
			result.groundY = root.get("groundY").asInt(result.groundY);
			if (result.worldWidth < 640) result.worldWidth = 1920;
			result.music = root.get("music").asString("");

			var player = root.get("player").asObject();
			if (player != null)
			{
				result.playerX = player.get("x").asInt(result.playerX);
				result.playerY = player.get("y").asInt(result.playerY);
			}

			var backgroundArray = root.get("backgrounds").asArray();
			if (backgroundArray != null)
			{
				for (i in 0...backgroundArray.length)
				{
					var item = backgroundArray.get(i).asObject();
					if (item == null) continue;
					var image = item.get("image").asString("");
					if (image == "") continue;
					result.backgrounds.push({
						image: image,
						x: item.get("x").asInt(0),
						y: item.get("y").asInt(0),
						scrollX: item.get("scrollX").asInt(1000),
						scrollY: item.get("scrollY").asInt(1000)
					});
				}
			}

			var flashArray = root.get("flashes").asArray();
			if (flashArray != null)
			{
				for (i in 0...flashArray.length)
				{
					var item = flashArray.get(i).asObject();
					if (item == null) continue;
					result.flashes.push({
						x: item.get("x").asInt(0),
						y: item.get("y").asInt(0),
						value: item.get("value").asInt(1)
					});
				}
			}
			return result;
		}
		catch (e:Dynamic)
		{
			trace("[LevelBin] Failed to parse " + relative + ": " + Std.string(e));
			return null;
		}
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

