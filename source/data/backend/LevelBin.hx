package data.backend;

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

class LevelBin
{
	public var name:String = "ATown";
	public var playerX:Int = 500;
	public var playerY:Int = 130;
	public var backgrounds:Array<LevelBackgroundData> = [];
	public var flashes:Array<LevelFlashData> = [];

	public static function load(stage:String):LevelBin
	{
		var relative:String = 'levels/$stage/Level.bin';
		var path:String = Paths.getSharedPath(relative);
		var parsed:bin.BINValue = null;

		try
		{
			#if sys
			#if MODS_ALLOWED
			var modPath:String = Paths.modFolders(relative);
			if (FileSystem.exists(modPath))
				parsed = bin.BIN.read(modPath);
			else
			#end
			if (FileSystem.exists(path))
				parsed = bin.BIN.read(path);
			#else
			if (Assets.exists(path))
				parsed = bin.BIN.parse(Assets.getBytes(path));
			#end

			if (parsed == null || !parsed.isObject())
			{
				trace('[LevelBin] No Level.bin found for $stage; using fallback stage.');
				return null;
			}

			var root = parsed.asObject();
			var result = new LevelBin();
			result.name = root.get("name").asString(stage);

			var playerData = root.get("player").asObject();
			if (playerData != null)
			{
				result.playerX = playerData.get("x").asInt(result.playerX);
				result.playerY = playerData.get("y").asInt(result.playerY);
			}

			var backgroundData = root.get("backgrounds").asArray();
			if (backgroundData != null)
			{
				for (i in 0...backgroundData.length)
				{
					var item = backgroundData.get(i).asObject();
					if (item == null) continue;
					var image = item.get("image").asString("");
					if (image.length == 0) continue;
					result.backgrounds.push({
						image: image,
						x: item.get("x").asInt(0),
						y: item.get("y").asInt(0),
						scrollX: item.get("scrollX").asInt(1000),
						scrollY: item.get("scrollY").asInt(1000)
					});
				}
			}

			var flashData = root.get("flashes").asArray();
			if (flashData != null)
			{
				for (i in 0...flashData.length)
				{
					var item = flashData.get(i).asObject();
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
			trace('[LevelBin] Failed to read $path: $e');
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
