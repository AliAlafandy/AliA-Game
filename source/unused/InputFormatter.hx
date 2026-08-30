package;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadManager;

enum abstract LabelStyle(Int)
{
	var FULL = 0;
	var SHORT = 1;
	var GLYPH_PATH = 2;
}

class InputFormatter
{
	private static var cachedModel:FlxGamepadModel = UNKNOWN;
	private static var cachedGamepadId:Int = -1;

	public static function getKeyName(key:FlxKey, ?style:LabelStyle = FULL):String
	{
		switch (key)
		{
			case BACKSPACE:
				return style == SHORT ? "Bksp" : "BckSpc";
			case CONTROL:
				return "Ctrl";
			case ALT:
				return "Alt";
			case SHIFT:
				return "Shift";
			case CAPSLOCK:
				return "Caps";
			case TAB:
				return "Tab";
			case ENTER:
				return "Enter";
			case ESCAPE:
				return "Esc";
			case SPACE:
				return style == SHORT ? "Spc" : "Space";
			case PAGEUP:
				return "PgUp";
			case PAGEDOWN:
				return "PgDown";
			case HOME:
				return "Home";
			case END:
				return "End";
			case INSERT:
				return "Ins";
			case DELETE:
				return "Del";
			case ZERO: return "0";
			case ONE: return "1";
			case TWO: return "2";
			case THREE: return "3";
			case FOUR: return "4";
			case FIVE: return "5";
			case SIX: return "6";
			case SEVEN: return "7";
			case EIGHT: return "8";
			case NINE: return "9";
			case NUMPADZERO: return "#0";
			case NUMPADONE: return "#1";
			case NUMPADTWO: return "#2";
			case NUMPADTHREE: return "#3";
			case NUMPADFOUR: return "#4";
			case NUMPADFIVE: return "#5";
			case NUMPADSIX: return "#6";
			case NUMPADSEVEN: return "#7";
			case NUMPADEIGHT: return "#8";
			case NUMPADNINE: return "#9";
			case NUMPADMULTIPLY: return "#*";
			case NUMPADPLUS: return "#+";
			case NUMPADMINUS: return "#-";
			case NUMPADPERIOD: return "#.";
			case NUMPADSLASH: return "#/";
			case SEMICOLON: return ";";
			case COMMA: return ",";
			case PERIOD: return ".";
			case SLASH: return "/";
			case BACKSLASH: return "\\";
			case GRAVEACCENT: return "`";
			case LBRACKET: return "[";
			case RBRACKET: return "]";
			case QUOTE: return "'";
			case MINUS: return "-";
			case PLUS: return "+";
			case PRINTSCREEN:
				return style == SHORT ? "PrtSc" : "PrtScrn";
			case UP: return "Up";
			case DOWN: return "Down";
			case LEFT: return "Left";
			case RIGHT: return "Right";
			case NONE:
				return '---';
			default:
				var label:String = Std.string(key);
				if (label.toLowerCase() == 'null')
					return '---';

				var arr:Array<String> = label.split('_');
				for (i in 0...arr.length)
					arr[i] = CoolUtil.capitalize(arr[i]);
				return arr.join(' ');
		}
	}

	public static function getGamepadModel():FlxGamepadModel
	{
		var gamepad:FlxGamepad = FlxG.gamepads.firstActive;
		if (gamepad == null)
			return UNKNOWN;

		if (gamepad.id == cachedGamepadId)
			return cachedModel;

		cachedGamepadId = gamepad.id;
		cachedModel = gamepad.detectedModel;
		return cachedModel;
	}

	public static function invalidateGamepadCache():Void
	{
		cachedGamepadId = -1;
		cachedModel = UNKNOWN;
	}

	public static function getGamepadName(key:FlxGamepadInputID, ?style:LabelStyle = FULL):String
	{
		var model:FlxGamepadModel = getGamepadModel();

		switch (key)
		{
			case LEFT_STICK_DIGITAL_LEFT:
				return style == SHORT ? "L. Left" : "Left";
			case LEFT_STICK_DIGITAL_RIGHT:
				return style == SHORT ? "L. Right" : "Right";
			case LEFT_STICK_DIGITAL_UP:
				return style == SHORT ? "L. Up" : "Up";
			case LEFT_STICK_DIGITAL_DOWN:
				return style == SHORT ? "L. Down" : "Down";
			case LEFT_STICK_CLICK:
				return switch (model)
				{
					case PS4: "L3";
					case XINPUT: "LS";
					case SWITCH: "L Click";
					case STEAM: "L Pad Click";
					default: "Analog Click";
				}

			case RIGHT_STICK_DIGITAL_LEFT:
				return "C. Left";
			case RIGHT_STICK_DIGITAL_RIGHT:
				return "C. Right";
			case RIGHT_STICK_DIGITAL_UP:
				return "C. Up";
			case RIGHT_STICK_DIGITAL_DOWN:
				return "C. Down";
			case RIGHT_STICK_CLICK:
				return switch (model)
				{
					case PS4: "R3";
					case XINPUT: "RS";
					case SWITCH: "R Click";
					case STEAM: "R Pad Click";
					default: "C. Click";
				}

			case DPAD_LEFT:
				return "D. Left";
			case DPAD_RIGHT:
				return "D. Right";
			case DPAD_UP:
				return "D. Up";
			case DPAD_DOWN:
				return "D. Down";

			case LEFT_SHOULDER:
				return switch (model)
				{
					case PS4: "L1";
					case XINPUT: "LB";
					case SWITCH: "L";
					default: "L. Bumper";
				}
			case RIGHT_SHOULDER:
				return switch (model)
				{
					case PS4: "R1";
					case XINPUT: "RB";
					case SWITCH: "R";
					default: "R. Bumper";
				}
			case LEFT_TRIGGER, LEFT_TRIGGER_BUTTON:
				return switch (model)
				{
					case PS4: "L2";
					case XINPUT: "LT";
					case SWITCH: "ZL";
					default: "L. Trigger";
				}
			case RIGHT_TRIGGER, RIGHT_TRIGGER_BUTTON:
				return switch (model)
				{
					case PS4: "R2";
					case XINPUT: "RT";
					case SWITCH: "ZR";
					default: "R. Trigger";
				}

			case A:
				return switch (model)
				{
					case PS4: "X";
					case XINPUT: "A";
					case SWITCH: "B";
					default: "Action Down";
				}
			case B:
				return switch (model)
				{
					case PS4: "O";
					case XINPUT: "B";
					case SWITCH: "A";
					default: "Action Right";
				}
			case X:
				return switch (model)
				{
					case PS4: "[";
					case XINPUT: "X";
					case SWITCH: "Y";
					default: "Action Left";
				}
			case Y:
				return switch (model)
				{
					case PS4: "]";
					case XINPUT: "Y";
					case SWITCH: "X";
					default: "Action Up";
				}

			case BACK:
				return switch (model)
				{
					case PS4: "Share";
					case XINPUT: "Back";
					case SWITCH: "Minus";
					default: "Select";
				}
			case START:
				return switch (model)
				{
					case PS4: "Options";
					case SWITCH: "Plus";
					default: "Start";
				}
			case GUIDE:
				return switch (model)
				{
					case PS4: "PS";
					case XINPUT: "Guide";
					case SWITCH: "Home";
					default: "Guide";
				}

			case NONE:
				return '---';

			default:
				var label:String = Std.string(key);
				if (label.toLowerCase() == 'null')
					return '---';

				var arr:Array<String> = label.split('_');
				for (i in 0...arr.length)
					arr[i] = CoolUtil.capitalize(arr[i]);
				return arr.join(' ');
		}
	}

	public static function getGlyphPath(key:FlxGamepadInputID):String
	{
		var model:FlxGamepadModel = getGamepadModel();
		var modelFolder:String = switch (model)
		{
			case PS4: "ps4";
			case XINPUT: "xbox";
			case SWITCH: "switch";
			case STEAM: "steam";
			default: "generic";
		};

		var buttonId:String = Std.string(key).toLowerCase();
		return 'images/glyphs/$modelFolder/$buttonId';
	}

	public static function formatBinding(keyboardKeys:Array<FlxKey>, gamepadButtons:Array<FlxGamepadInputID>, ?style:LabelStyle = FULL, ?separator:String = " / "):String
	{
		var parts:Array<String> = [];

		if (keyboardKeys != null)
		{
			for (key in keyboardKeys)
			{
				if (key == NONE)
					continue;
				parts.push(getKeyName(key, style));
			}
		}

		if (gamepadButtons != null && FlxG.gamepads.firstActive != null)
		{
			for (button in gamepadButtons)
			{
				if (button == NONE)
					continue;
				parts.push(getGamepadName(button, style));
			}
		}

		return parts.length > 0 ? parts.join(separator) : '---';
	}

	public static function isConflicting(keyA:FlxKey, keyB:FlxKey):Bool
	{
		return keyA != NONE && keyA == keyB;
	}

	public static function findConflicts(action:String, key:FlxKey, allBinds:Map<String, Array<FlxKey>>):Array<String>
	{
		var conflicts:Array<String> = [];

		for (otherAction => keys in allBinds)
		{
			if (otherAction == action)
				continue;

			for (boundKey in keys)
			{
				if (isConflicting(key, boundKey))
				{
					conflicts.push(otherAction);
					break;
				}
			}
		}

		return conflicts;
	}
}
