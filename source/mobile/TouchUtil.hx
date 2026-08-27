package mobile;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxG;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;

enum SwipeDirection
{
	UP;
	DOWN;
	LEFT;
	RIGHT;
}

class TouchUtil
{
	public static var pressed(get, never):Bool;
	public static var justPressed(get, never):Bool;
	public static var justReleased(get, never):Bool;
	public static var released(get, never):Bool;
	public static var touch(get, never):FlxTouch;
	public static var touchCount(get, never):Int;
	public static var hasMultiTouch(get, never):Bool;

	public static function overlaps(object:FlxObject, ?camera:FlxCamera):Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.overlaps(object, camera ?? object.camera))
				return true;

		return false;
	}

	public static function overlapsComplex(object:FlxObject, ?camera:FlxCamera):Bool
	{
		if (camera == null)
		{
			for (cam in object.cameras)
				for (touch in FlxG.touches.list)
					@:privateAccess
					if (object.overlapsPoint(touch.getWorldPosition(cam, object._point), true, cam))
						return true;
		}
		else
		{
			for (touch in FlxG.touches.list)
				@:privateAccess
				if (object.overlapsPoint(touch.getWorldPosition(camera, object._point), true, camera))
					return true;
		}

		return false;
	}

	public static function getOverlapping(object:FlxObject, ?camera:FlxCamera):FlxTouch
	{
		for (touch in FlxG.touches.list)
			if (touch.overlaps(object, camera ?? object.camera))
				return touch;

		return null;
	}

	public static function pressedOn(object:FlxObject, ?camera:FlxCamera):Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.pressed && touch.overlaps(object, camera ?? object.camera))
				return true;

		return false;
	}

	public static function justPressedOn(object:FlxObject, ?camera:FlxCamera):Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.justPressed && touch.overlaps(object, camera ?? object.camera))
				return true;

		return false;
	}

	public static function justReleasedOn(object:FlxObject, ?camera:FlxCamera):Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.justReleased && touch.overlaps(object, camera ?? object.camera))
				return true;

		return false;
	}

	public static function getSwipeDirection(touch:FlxTouch, minDistance:Float = 50):Null<SwipeDirection>
	{
		if (touch == null || touch.justPressedPosition == null)
			return null;

		var dx:Float = touch.x - touch.justPressedPosition.x;
		var dy:Float = touch.y - touch.justPressedPosition.y;

		if (Math.abs(dx) < minDistance && Math.abs(dy) < minDistance)
			return null;

		if (Math.abs(dx) > Math.abs(dy))
			return dx > 0 ? RIGHT : LEFT;

		return dy > 0 ? DOWN : UP;
	}

	public static function getTouchById(id:Int):FlxTouch
	{
		for (touch in FlxG.touches.list)
			if (touch.touchPointID == id)
				return touch;

		return null;
	}

	@:noCompletion
	private static function get_pressed():Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.pressed)
				return true;

		return false;
	}

	@:noCompletion
	private static function get_justPressed():Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.justPressed)
				return true;

		return false;
	}

	@:noCompletion
	private static function get_justReleased():Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.justReleased)
				return true;

		return false;
	}

	@:noCompletion
	private static function get_released():Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.released)
				return true;

		return false;
	}

	@:noCompletion
	private static function get_touch():FlxTouch
	{
		for (touch in FlxG.touches.list)
			if (touch != null)
				return touch;

		return FlxG.touches.getFirst();
	}

	@:noCompletion
	private static function get_touchCount():Int
	{
		return FlxG.touches.list.length;
	}

	@:noCompletion
	private static function get_hasMultiTouch():Bool
	{
		return FlxG.touches.list.length > 1;
	}
}
