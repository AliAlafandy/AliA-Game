package data.backend;

import bin.BIN;
import bin.BINValue;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.utils.Assets;

#if sys
import sys.FileSystem;
#end

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

/**
 * Binary Level.bin data model.
 *
 * This is deliberately separate from StageData:
 * - StageData loads Act<act>.bin and chooses the stage asset directory.
 * - LevelBin loads the editor/gameplay Level.bin containing spawn, backgrounds and flashes.
 */
class LevelBin
{
	public function new() {}

	public var name:String = "ATown";
	public var music:String = "";
	public var playerX:Int = 500;
	public var playerY:Int = 130;
	public var backgrounds:Array<LevelBackgroundData> = [];
	public var flashes:Array<LevelFlashData> = [];

	public static function load(stage:String):LevelBin
	{
		var relative = "levels/" + stage + "/Level.bin";
		var path = StageData.getLevelAssetPath(stage, StageData.currentAct, "Level.bin");
		var parsed:BINValue = null;

		try
		{
			#if sys
			#if MODS_ALLOWED
			if (FileSystem.exists(path))
				parsed = BIN.read(path);
			else
			#end
			if (FileSystem.exists(path))
				parsed = BIN.read(path);
			#else
			if (Assets.exists(path))
			{
				var bytes = Assets.getBytes(path);
				if (bytes != null) parsed = BIN.parse(bytes);
			}
			#end

			if (parsed == null || !parsed.isObject())
			{
				trace("[LevelBin] Missing or invalid " + relative);
				return null;
			}

			var root = parsed.asObject();
			var result = new LevelBin();
			result.name = root.get("name").asString(stage);
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
			sprite.loadGraphic(Paths.image(data.image));
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
