package data.objects;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;

import openfl.utils.Assets;
import haxe.Json;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

import data.backend.Paths;

typedef CharacterFile = {
	var charName:String;
	var anim:Array<AnimArray>;
}

typedef AnimArray = {
	var name:String;
	var image:String;
	var prefix:String;
	var offsets:Array<Int>;
	var loop:Bool;
	var scale:Float;
	var fps:Int;
	var indices:Array<Int>;
}

class Player extends FlxSprite
{
	public static final DEFAULT_CHARACTER:String = 'Ellawy';

	public var animOffsets:Map<Float, String> = new Map();
	public var debugMode:Bool = false;
	// public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var isPartner:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var animationsArray:Array<Null> = [];

	public function new(x:Float, y:Float, ?character:String = 'Ellawy', ?isPartner:Bool = false)
	{
		super(x, y);
	
		curCharacter = character;
		this.isPartner = isPartner;
	
		var jsonKey:String = 'characters/$curCharacter/$curCharacter';
		var path:String = Paths.getPath('$jsonKey.json', TEXT, null, true);
	
		try
		{
			#if MODS_ALLOWED
			if (FileSystem.exists(path))
				loadCharacterFile(Json.parse(File.getContent(path)));
			#else
			if (Assets.exists(path))
				loadCharacterFile(Json.parse(Assets.getText(path)));
			#end
		}
		catch (e:Dynamic)
		{
			FlxG.log.warn('Could not load character json: $e');
		}
	
		if (animationsArray.length > 0)
		{
			playAnim(animationsArray[0].name);
		}
	}

	public function loadCharacterFile(json:CharacterFile)
	{
		scale.set(1, 1);
		updateHitbox();

		animationsArray = json.anim;
		if (animationsArray != null && animationsArray.length > 0)
		{
			for (anim in animationsArray)
			{
				var animName:String = anim.name;
				var imageName:String = anim.image;
				var animPrefix:String = anim.prefix;
				var animFps:Int = anim.fps;
				var animLoop:Bool = anim.loop;
				var animIndices:Array = anim.indices;

				var assetKey:String = 'characters/$curCharacter/$imageName';

				var imageLoaded = Paths.image(assetKey, null, true);
				var xmlPath = Paths.getPath('$assetKey.xml', TEXT, null, true);

				if (imageLoaded != null && Paths.fileExists('$assetKey.xml', TEXT, true))
				{
					var xmlContent:String = "";
					#if MODS_ALLOWED
					if (FileSystem.exists(xmlPath))
						xmlContent = File.getContent(xmlPath);
					else
					#end
						xmlContent = Assets.getText(xmlPath);

					var spritemap = FlxAtlasFrames.fromSparrow(imageLoaded, xmlContent);
					if (frames == null)
						frames = spritemap;
					else
						frames.addAtlas(spritemap);
				}

				if (animIndices != null && animIndices.length > 0)
				{
					animation.addByIndices(animName, animPrefix, animIndices, "", animFps, animLoop);
				}
				else
				{
					animation.addByPrefix(animName, animPrefix, animFps, animLoop);
				}

				if (anim.offsets != null && anim.offsets.length > 1)
					addOffset(animName, anim.offsets[0], anim.offsets[1]);
				else
					addOffset(animName, 0, 0);
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);

		if (animOffsets.exists(AnimName))
		{
			var daOffset = animOffsets.get(AnimName);
			offset.set(daOffset[0], daOffset[1]);
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
