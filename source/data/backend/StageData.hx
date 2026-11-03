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
 * Every level may provide one <LevelName>.bin image archive at:
 * assets/levels/<LevelName>/<LevelName>.bin
 *
 * The archive stores the original PNG files as base64 records:
 * LEVELASSETS|1
 * image.png|<base64 PNG bytes>
 *
 * Act<act>.bin remains the stage metadata file used for stage directory
 * selection. Level.bin remains the gameplay/editor data file handled by
 * LevelBin.
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
			#else
			if (Assets.exists(path))
			{
				var bytes = Assets.getBytes(path);
				if (bytes != null) return BIN.parse(bytes);
			}
			#end
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
			#else
			if (Assets.exists(path)) content = Assets.getText(path);
			#end
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
					case "sun.png": sprite.y = 60; sprite.scrollFactor.set(0.08, 0.08);
					case "clouds.png": sprite.y = 40; sprite.scrollFactor.set(0.12, 0.08);
					case "buildings.png": sprite.y = 150; sprite.scrollFactor.set(0.35, 0.35);
					case "sidewalk.png": sprite.y = FlxG.height - bitmap.height - 48; sprite.scrollFactor.set(0.8, 0.8);
					case "street.png":
						sprite.y = FlxG.height - bitmap.height;
						sprite.scrollFactor.set(1, 1);
						// The road image is also the physical floor.
						groundSprite = sprite;
						floorCollider = new FlxSprite(0, sprite.y);
						floorCollider.makeGraphic(Std.int(Math.max(bitmap.width, FlxG.width)), 12, 0x00000000);
						floorCollider.visible = false;
						floorCollider.immovable = true;
						floorCollider.allowCollisions = flixel.util.FlxDirectionFlags.UP;
				}
				group.add(sprite);
			}
			if (floorCollider != null) group.add(floorCollider);
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
				if (bitmap != null && !bitmap.isDisposed) bitmap.dispose();
				decodedImages.remove(key);
			}
		}
		groundSprite = null;
		floorCollider = null;
	}
}
