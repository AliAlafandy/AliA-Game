package data.objects;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.util.FlxDirectionFlags;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;

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

	public var curCharacter:String = DEFAULT_CHARACTER;
	public var animOffsets:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();
	public var animationsArray:Array<AnimArray> = [];

	public var isPartner:Bool = false;
	public var debugMode:Bool = false;

	public var moveSpeed:Float = 260;
	public var maxMoveSpeed:Float = 260;
	public var moveAcceleration:Float = 1800;
	public var moveFriction:Float = 2200;

	public var jumpSpeed:Float = 560;
	public var gravityForce:Float = 1500;
	public var maxFallSpeed:Float = 1000;

	public var canMove:Bool = true;
	public var grounded:Bool = false;
	public var moveDirection:Int = 0;
	private var lastMovementAnimation:String = "";

	public function new(x:Float, y:Float, character:String = 'Ellawy', ?isPartner:Bool = false)
	{
		super(x, y);

		this.isPartner = isPartner;

		if (character == null || character.length == 0)
			character = DEFAULT_CHARACTER;

		curCharacter = character;

		loadCharacter();
	}

	private function loadCharacter():Void
	{
		var jsonKey:String = 'characters/$curCharacter/$curCharacter';
		var path:String = Paths.getPath('$jsonKey.json', TEXT, null, true);
		var loaded:Bool = false;

		try
		{
			#if MODS_ALLOWED
			if (FileSystem.exists(path))
			{
				var jsonText:String = File.getContent(path);
				var parsed:Dynamic = Json.parse(jsonText);

				loadCharacterFile(parsed);
				loaded = true;
			}
			#else
			if (Assets.exists(path))
			{
				var jsonText:String = Assets.getText(path);
				var parsed:Dynamic = Json.parse(jsonText);

				loadCharacterFile(parsed);
				loaded = true;
			}
			#end
		}
		catch (e:Dynamic)
		{
			FlxG.log.warn('Could not load character "$curCharacter": $e');
		}

		if (!loaded)
		{
			FlxG.log.warn('Character JSON not found: $path');
		}

		setupPhysics();

		if (animation.exists('idle'))
		{
			playAnim('idle');
			lastMovementAnimation = 'idle';
		}
		else if (animationsArray != null && animationsArray.length > 0)
		{
			var firstAnimation:String = animationsArray[0].name;
			if (animation.exists(firstAnimation))
			{
				playAnim(firstAnimation);
				lastMovementAnimation = firstAnimation;
			}
		}
	}

	public function loadCharacterFile(json:CharacterFile):Void
	{
		if (json == null)
			return;

		scale.set(1, 1);
		updateHitbox();

		animationsArray = json.anim;

		if (animationsArray == null)
			animationsArray = [];

		for (anim in animationsArray)
		{
			if (anim == null)
				continue;

			var animName:String = anim.name;
			var imageName:String = anim.image;
			var animPrefix:String = anim.prefix;
			var animFps:Int = anim.fps;
			var animLoop:Bool = anim.loop;
			var animIndices:Array<Int> = anim.indices;

			if (animName == null || animName.length == 0)
				continue;

			if (imageName == null || imageName.length == 0)
				imageName = curCharacter;

			if (animPrefix == null || animPrefix.length == 0)
				animPrefix = animName;

			if (animFps <= 0)
				animFps = 12;

			var assetKey:String = 'characters/$curCharacter/$imageName';

			try
			{
				var imageLoaded = Paths.image(assetKey, null, true);

				var xmlExists:Bool = Paths.fileExists('$assetKey.xml', TEXT, true);
				if (imageLoaded != null && xmlExists)
				{
					var xmlPath:String = Paths.getPath('$assetKey.xml', TEXT, null, true);
					var xmlContent:String = "";

					#if MODS_ALLOWED
					if (FileSystem.exists(xmlPath))
					{
						xmlContent = File.getContent(xmlPath);
					}
					else
					#end

					if (Assets.exists(xmlPath))
					{
						xmlContent = Assets.getText(xmlPath);
					}

					if (xmlContent.length > 0)
					{
						var spriteMap:FlxAtlasFrames = FlxAtlasFrames.fromSparrow(imageLoaded, xmlContent);
						if (spriteMap != null)
						{
							if (frames == null)
							{
								frames = spriteMap;
							} else {
								for (frame in spriteMap.frames)
								{
									if (!frames.frames.contains(frame))
										frames.frames.push(frame);
								}
							}
						}
					}
				}
			}
			catch (e:Dynamic)
			{
				FlxG.log.warn('Failed to load atlas for ' + '$curCharacter/$imageName: $e');
			}

			if (animIndices != null && animIndices.length > 0)
			{
				animation.addByIndices(animName, animPrefix, animIndices, "", animFps, animLoop);
			} else {
				animation.addByPrefix(animName, animPrefix, animFps, animLoop);
			}

			if (anim.offsets != null && anim.offsets.length >= 2)
			{
				addOffset(animName, anim.offsets[0], anim.offsets[1]);
			} else {
				addOffset(animName, 0, 0);
			}
		}

		if (animationsArray != null && animationsArray.length > 0)
		{
			var characterScale:Float = animationsArray[0].scale;
			if (characterScale <= 0)
				characterScale = 1;

			scale.set(characterScale, characterScale);
			updateHitbox();
		}
	}

	public function setupPhysics():Void
	{
		acceleration.y = gravityForce;
		maxVelocity.x = maxMoveSpeed;
		maxVelocity.y = maxFallSpeed;
		drag.x = moveFriction;
		immovable = false;
		allowCollisions = FlxDirectionFlags.ANY;
	}

	public function moveCharacter(direction:Float, jumpPressed:Bool):Void
	{
		if (!canMove)
		{
			stopHorizontalMovement();
			updateMovementAnimation();
			return;
		}

		if (direction < -1)
			direction = -1;

		if (direction > 1)
			direction = 1;

		if (direction < 0)
			moveDirection = -1;
		else if (direction > 0)
			moveDirection = 1;
		else
			moveDirection = 0;

		if (direction != 0)
		{
			velocity.x = FlxMath.lerp(velocity.x, direction * moveSpeed, 0.20);

			if (direction < 0)
				facing = FlxDirectionFlags.LEFT;
			else
				facing = FlxDirectionFlags.RIGHT;
		} else {
			if (velocity.x > 0)
			{
				velocity.x -= moveFriction * FlxG.elapsed;
				if (velocity.x < 0)
					velocity.x = 0;
			} else if (velocity.x < 0) {
				velocity.x += moveFriction * FlxG.elapsed;
				if (velocity.x > 0)
					velocity.x = 0;
			}
		}

		if (jumpPressed && grounded)
		{
			velocity.y = -jumpSpeed;
			grounded = false;
		}

		updateMovementAnimation();
	}

	private function stopHorizontalMovement():Void
	{
		if (Math.abs(velocity.x) < 10)
		{
			velocity.x = 0;
			return;
		}

		if (velocity.x > 0)
		{
			velocity.x -= moveFriction * FlxG.elapsed;
			if (velocity.x < 0)
				velocity.x = 0;
		} else {
			velocity.x += moveFriction * FlxG.elapsed;
			if (velocity.x > 0)
				velocity.x = 0;
		}
	}

	public function updateMovementAnimation():Void
	{
		if (!grounded && velocity.y < 0) {
			playMovementAnimation('jump', 'idle');
			return;
		}
		if (!grounded && velocity.y >= 0) {
			playMovementAnimation('fall', 'jump');
			return;
		}
		if (grounded && Math.abs(velocity.x) > moveSpeed * 0.75)
		{
			if (animation.exists('run'))
			{
				playMovementAnimation('run', 'walk');
				return;
			}
		}
		if (grounded && Math.abs(velocity.x) > 10) {
			playMovementAnimation('walk', 'idle');
			return;
		}
		if (grounded) {
			playMovementAnimation('idle', 'waiting');
		}
	}

	private function playMovementAnimation(preferred:String, fallback:String):Void
	{
		var animationName:String = preferred;

		if (!animation.exists(animationName))
			animationName = fallback;

		if (!animation.exists(animationName))
			return;

		if (lastMovementAnimation == animationName) {
			return;
		}

		playAnim(animationName);
		lastMovementAnimation = animationName;
	}

	public function updateGroundState():Void
	{
		grounded = isTouching(FlxDirectionFlags.FLOOR);
		updateMovementAnimation();
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (!animation.exists(AnimName))
			return;

		animation.play(AnimName, Force, Reversed, Frame);

		if (animOffsets.exists(AnimName))
		{
			var daOffset = animOffsets.get(AnimName);
			offset.set(daOffset[0], daOffset[1]);
		} else {
			offset.set(0, 0);
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0):Void
	{
		animOffsets.set(name, [x, y]);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (velocity.y > maxFallSpeed)
			velocity.y = maxFallSpeed;
	}
}
