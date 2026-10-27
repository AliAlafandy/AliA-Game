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
	public var animScales:Map<String, Float> = new Map<String, Float>();
	public var animationsArray:Array<AnimArray> = [];

	public var isPartner:Bool = false;
	public var followTarget:Player = null;
	public var debugMode:Bool = ClientPrefs.getGameplaySetting("debugMode");

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
	public var isJumping:Bool = false;
	public var hasJumped:Bool = false;
	
	private var idleTimer:Float = 0;
	private static inline var IDLE_TIMEOUT:Float = 300.0;

	public function new(x:Float, y:Float, character:String = 'Ellawy', ?isPartner:Bool = false)
	{
		super(x, y);

		this.isPartner = isPartner;

		if (character == null || character.length == 0)
			character = DEFAULT_CHARACTER;

		curCharacter = character;

		loadCharacter();

		if (curCharacter.toLowerCase() == 'ellawy')
		{
			moveSpeed = 820;
			maxMoveSpeed = 820;
			moveAcceleration = 3200;
			moveFriction = 1050;
			jumpSpeed = 620;
			maxFallSpeed = 1150;
			setupPhysics();
		}
	}

	private function loadCharacter():Void
	{
		var jsonKey:String = 'characters/$curCharacter/$curCharacter.json';
		var loaded:Bool = false;

		try
		{
			var jsonText:String = Paths.getTextFromFile(jsonKey, false);
			
			if (jsonText != null)
			{
				var parsed:Dynamic = Json.parse(jsonText);
				loadCharacterFile(parsed);
				loaded = true;
				trace('[Player] Loaded character JSON: $jsonKey');
			}
			else
			{
				var lowerKey:String = curCharacter.toLowerCase();
				var lowerJsonKey:String = 'characters/$lowerKey/$lowerKey.json';
				
				jsonText = Paths.getTextFromFile(lowerJsonKey, false);
				if (jsonText != null)
				{
					var parsed:Dynamic = Json.parse(jsonText);
					loadCharacterFile(parsed);
					loaded = true;
					trace('[Player] Loaded character JSON (Lowercase Fallback): $lowerJsonKey');
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('[Player] Could not parse character "$curCharacter": $e');
		}

		if (!loaded)
		{
			trace('[Player] Character JSON not found for: $curCharacter');
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
		{
			trace('[Player] loadCharacterFile received null JSON');
			return;
		}

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
		    var animScale:Float = anim.scale;
		
		    if (animName == null || animName.length == 0)
		        continue;
		
		    if (imageName == null || imageName.length == 0)
		        imageName = curCharacter;
		
		    if (animPrefix == null || animPrefix.length == 0)
		        animPrefix = animName;
		
		    if (animFps <= 0)
		        animFps = 12;
		
		    if (animScale <= 0)
		        animScale = 1;
		
		    animScales.set(animName, animScale);
		
		    var assetKey:String = '$curCharacter/$imageName';
		    trace('[Player] Requesting Atlas for assetKey: "$assetKey"');
		
		    try
		    {
		        if (frames == null)
		        {
		            var spriteMap:FlxAtlasFrames = Paths.getCharacterSparrowAtlas(assetKey, false);
		            if (spriteMap != null) {
		                frames = spriteMap;
		                trace('[Player] SUCCESS: Atlas loaded for "$assetKey"');
		            } else {
		                trace('[Player] FAILED: Atlas returned null for "$assetKey" (Check Paths.hx logs above this)');
		            }
		        }
		    }
		    catch (e:Dynamic) 
		    {
		        trace('[Player] EXCEPTION loading Atlas for "$assetKey": $e');
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

	public function moveCharacter(direction:Float, jumpPressed:Bool, upPressed:Bool, downPressed:Bool):Void
	{
		if (!canMove)
		{
			stopHorizontalMovement();
			updateMovementAnimation(false, false);
			return;
		}

		if (direction != 0 || jumpPressed || upPressed || downPressed)
		{
			idleTimer = 0;
		}

		if (direction < -1)
			direction = -1;

		if (direction > 1)
			direction = 1;

		if (direction < 0)
		{
			moveDirection = -1;
			flipX = true;
		}
		else if (direction > 0)
		{
			moveDirection = 1;
			flipX = false;
		}

		if (direction != 0)
		{
			var accelerationBlend:Float = 1 - Math.exp(-moveAcceleration * FlxG.elapsed / Math.max(moveSpeed, 1));
			velocity.x = FlxMath.lerp(velocity.x, direction * moveSpeed, accelerationBlend);
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

		var isOnGround:Bool = grounded || isTouching(FlxDirectionFlags.FLOOR) || velocity.y == 0;

		if (jumpPressed && isOnGround)
		{
			velocity.y = -jumpSpeed;
			grounded = false;
			isJumping = true;
			hasJumped = true;
		}

		if (isOnGround)
		{
			isJumping = false;
			hasJumped = false;
		}

		updateMovementAnimation(upPressed, downPressed);
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

	public function updateMovementAnimation(upPressed:Bool, downPressed:Bool):Void
	{
		var isOnGround:Bool = grounded || isTouching(FlxDirectionFlags.FLOOR) || velocity.y == 0;
	
		if (isOnGround) {
			isJumping = false;
			hasJumped = false;
		}
	
		if (isOnGround && Math.abs(velocity.x) <= 10)
		{
			if (upPressed) {
				playMovementAnimation('up', 'idle');
				return;
			}
			if (downPressed) {
				playMovementAnimation('down', 'idle');
				return;
			}
			if (downPressed && hasJumped) {
				playMovementAnimation('jumping', 'idle');
				return;
			}
		}
	
		if (!isOnGround)
		{
			if (hasJumped) {
				playMovementAnimation('jumping', 'jump');
				return;
			} else {
				playMovementAnimation('fall', 'idle');
				return;
			}
		}
	
		if (isOnGround && Math.abs(velocity.x) > moveSpeed * 0.75)
		{
			if (animation.exists('running') || animation.exists('run')) {
				playMovementAnimation('running', 'run');
				return;
			}
		}
		if (isOnGround && Math.abs(velocity.x) > 10)
		{
			playMovementAnimation('walking', 'walk');
			return;
		}
		if (isOnGround)
		{
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
		grounded = isTouching(FlxDirectionFlags.FLOOR) || touching.has(FlxDirectionFlags.FLOOR) || (velocity.y == 0);
		if (grounded)
		{
			isJumping = false;
			hasJumped = false;
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
	    if (!animation.exists(AnimName))
	        return;
	
	    animation.play(AnimName, Force, Reversed, Frame);
	
	    if (animScales.exists(AnimName))
	    {
	        var daScale:Float = animScales.get(AnimName);
	        scale.set(daScale, daScale);
	        updateHitbox();
	    }
	
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

		if (velocity.y > maxFallSpeed) velocity.y = maxFallSpeed;
		if (Math.abs(velocity.x) <= 10 && (grounded || isTouching(FlxDirectionFlags.FLOOR) || velocity.y == 0))
		{
			idleTimer += elapsed;
		} else {
			idleTimer = 0;
		}
	}

	public function updatePartnerAI(elapsed:Float):Void
	{
		if (followTarget == null) return;

		var distX = followTarget.x - x;
		var distY = followTarget.y - y;

		var targetOffsetX = 50 * (followTarget.flipX ? -1 : 1);
		var idealX = followTarget.x + targetOffsetX;
		var idealY = followTarget.y;

		var diffX = idealX - x;
		var diffY = idealY - y;

		flipX = followTarget.flipX;

		var isOnGround = grounded || isTouching(FlxDirectionFlags.FLOOR) || velocity.y == 0;

		if (followTarget.hasJumped && isOnGround && Math.abs(distX) < 200 && Math.abs(distY) < 150)
		{
			velocity.y = -jumpSpeed * 0.95;
			grounded = false;
			isJumping = true;
			hasJumped = true;
		}

		if (Math.abs(diffX) > 30 || Math.abs(diffY) > 30)
		{
			var dir = diffX > 0 ? 1 : -1;
			var accelerationBlend:Float = 1 - Math.exp(-moveAcceleration * elapsed / Math.max(moveSpeed, 1));
			velocity.x = FlxMath.lerp(velocity.x, dir * (moveSpeed * 0.9), accelerationBlend);
		} else {
			if (velocity.x > 0)
			{
				velocity.x -= moveFriction * elapsed;
				if (velocity.x < 0) velocity.x = 0;
			} else if (velocity.x < 0) {
				velocity.x += moveFriction * elapsed;
				if (velocity.x > 0) velocity.x = 0;
			}
		}

		if (!isOnGround)
		{
			if (hasJumped) playMovementAnimation('jumping', 'jump');
			else playMovementAnimation('fall', 'idle');
		} else if (Math.abs(velocity.x) > 10) {
			playMovementAnimation('walking', 'walk');
		} else {
			playMovementAnimation('idle', 'waiting');
		}
	}
}
