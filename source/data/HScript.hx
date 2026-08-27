package data;

import flixel.FlxBasic;

#if HSCRIPT_ALLOWED
import tea.SScript;

class HScript extends SScript
{
	public var modFolder:String;
	public var origin:String;

	override public function new(?file:String, ?varsToBring:Any = null)
	{
		if (file == null)
			file = '';

		this.varsToBring = varsToBring;
	
		super(file, false, false);

		if (scriptFile != null && scriptFile.length > 0)
		{
			this.origin = scriptFile;
			#if MODS_ALLOWED
			var myFolder:Array<String> = scriptFile.split('/');
			if(myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1])))
				this.modFolder = myFolder[1];
			#end
		}

		preset();
		execute();
	}

	var varsToBring:Any = null;
	override function preset() {
		super.preset();

		// Commonly used classes
		set('FlxG', flixel.FlxG);
		set('FlxMath', flixel.math.FlxMath);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxCamera', flixel.FlxCamera);
		set('PsychCamera', backend.PsychCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set('FlxColor', CustomFlxColor);
		set('PlayState', PlayState);
		set('Paths', Paths);
		set('StorageUtil', StorageUtil);
		set('ClientPrefs', ClientPrefs);
		#if ACHIEVEMENTS_ALLOWED
		set('Achievements', Achievements);
		#end
		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		set('StringTools', StringTools);
		#if flxanimate
		set('FlxAnimate', FlxAnimate);
		#end

		// Functions & Variables
		set('setVar', function(name:String, value:Dynamic) {
			PlayState.instance.variables.set(name, value);
			return value;
		});
		set('getVar', function(name:String) {
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});
		set('removeVar', function(name:String)
		{
			if(PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});
		set('debugPrint', function(text:String, ?color:flx.util.FlxColor = null) {
			if(color == null) color = flx.util.FlxColor.WHITE;
			PlayState.instance.addTextToDebug(text, color);
		});

		// Keyboard & Gamepads
		set('keyboardJustPressed', function(name:String) return Reflect.getProperty(flx.FlxG.keys.justPressed, name));
		set('keyboardPressed', function(name:String) return Reflect.getProperty(flx.FlxG.keys.pressed, name));
		set('keyboardReleased', function(name:String) return Reflect.getProperty(flx.FlxG.keys.justReleased, name));

		set('anyGamepadJustPressed', function(name:String) return flx.FlxG.gamepads.anyJustPressed(name));
		set('anyGamepadPressed', function(name:String) flx.FlxG.gamepads.anyPressed(name));
		set('anyGamepadReleased', function(name:String) return flx.FlxG.gamepads.anyJustReleased(name));

		set('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true)
		{
			var controller = flx.FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		set('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true)
		{
			var controller = flx.FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		set('gamepadJustPressed', function(id:Int, name:String)
		{
			var controller = flx.FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justPressed, name) == true;
		});
		set('gamepadPressed', function(id:Int, name:String)
		{
			var controller = flx.FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.pressed, name) == true;
		});
		set('gamepadReleased', function(id:Int, name:String)
		{
			var controller = flx.FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		set('keyJustPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.GAME_LEFT_P;
				case 'down': return Controls.instance.GAME_DOWN_P;
				case 'up': return Controls.instance.GAME_UP_P;
				case 'right': return Controls.instance.GAME_RIGHT_P;
				default: return Controls.instance.justPressed(name);
			}
			return false;
		});
		set('keyPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.GAME_LEFT;
				case 'down': return Controls.instance.GAME_DOWN;
				case 'up': return Controls.instance.GAME_UP;
				case 'right': return Controls.instance.GAME_RIGHT;
				default: return Controls.instance.pressed(name);
			}
			return false;
		});
		set('keyReleased', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.GAME_LEFT_R;
				case 'down': return Controls.instance.GAME_DOWN_R;
				case 'up': return Controls.instance.GAME_UP_R;
				case 'right': return Controls.instance.GAME_RIGHT_R;
				default: return Controls.instance.justReleased(name);
			}
			return false;
		});

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';

				set(libName, Type.resolveClass(str + libName));
			}
			catch (e:Dynamic) {
				var msg:String = e.message.substr(0, e.message.indexOf('\n'));
				if(PlayState.instance != null) PlayState.instance.addTextToDebug('$origin - $msg', flx.util.FlxColor.RED);
				else trace('$origin - $msg');
			}
		});
		set('this', this);
		set('game', flx.FlxG.state);
		
		set('add', flx.FlxG.state.add);
		set('insert', flx.FlxG.state.insert);
		set('remove', flx.FlxG.state.remove);

		if(PlayState.instance == flx.FlxG.state)
		{
			setSpecialObject(PlayState.instance, false, PlayState.instance.instancesExclude);
		}

		if(varsToBring != null) {
			for (key in Reflect.fields(varsToBring)) {
				key = key.trim();
				var value = Reflect.field(varsToBring, key);
				set(key, value);
			}
			varsToBring = null;
		}
	}

	public function executeCode(?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):TeaCall {
		if (funcToRun == null) return null;

		if(!exists(funcToRun)) {
			PlayState.instance.addTextToDebug(origin + ' - No HScript function named: $funcToRun', flx.util.FlxColor.RED);
			return null;
		}

		final callValue = call(funcToRun, funcArgs);
		if (!callValue.succeeded)
		{
			final e = callValue.exceptions[0];
			if (e != null) {
				var msg:String = e.toString();
				PlayState.instance.addTextToDebug('$origin - $msg', flx.util.FlxColor.RED);
			}
			return null;
		}
		return callValue;
	}

	public function executeFunction(funcToRun:String = null, funcArgs:Array<Dynamic>):TeaCall {
		if (funcToRun == null) return null;
		return call(funcToRun, funcArgs);
	}

	override public function destroy()
	{
		origin = null;
		super.destroy();
	}
}

class CustomFlxColor {
	public static var TRANSPARENT(default, null):Int = flx.util.FlxColor.TRANSPARENT;
	public static var BLACK(default, null):Int = flx.util.FlxColor.BLACK;
	public static var WHITE(default, null):Int = flx.util.FlxColor.WHITE;
	public static var GRAY(default, null):Int = flx.util.FlxColor.GRAY;

	public static var GREEN(default, null):Int = flx.util.FlxColor.GREEN;
	public static var LIME(default, null):Int = flx.util.FlxColor.LIME;
	public static var YELLOW(default, null):Int = flx.util.FlxColor.YELLOW;
	public static var ORANGE(default, null):Int = flx.util.FlxColor.ORANGE;
	public static var RED(default, null):Int = flx.util.FlxColor.RED;
	public static var PURPLE(default, null):Int = flx.util.FlxColor.PURPLE;
	public static var BLUE(default, null):Int = flx.util.FlxColor.BLUE;
	public static var BROWN(default, null):Int = flx.util.FlxColor.BROWN;
	public static var PINK(default, null):Int = flx.util.FlxColor.PINK;
	public static var MAGENTA(default, null):Int = flx.util.FlxColor.MAGENTA;
	public static var CYAN(default, null):Int = flx.util.FlxColor.CYAN;

	public static function fromInt(Value:Int):Int 
	{
		return cast flx.util.FlxColor.fromInt(Value);
	}

	public static function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):Int
	{
		return cast flx.util.FlxColor.fromRGB(Red, Green, Blue, Alpha);
	}
	public static function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):Int
	{	
		return cast flx.util.FlxColor.fromRGBFloat(Red, Green, Blue, Alpha);
	}

	public static inline function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):Int
	{
		return cast flx.util.FlxColor.fromCMYK(Cyan, Magenta, Yellow, Black, Alpha);
	}

	public static function fromHSB(Hue:Float, Sat:Float, Brt:Float, Alpha:Float = 1):Int
	{	
		return cast flx.util.FlxColor.fromHSB(Hue, Sat, Brt, Alpha);
	}
	public static function fromHSL(Hue:Float, Sat:Float, Light:Float, Alpha:Float = 1):Int
	{	
		return cast flx.util.FlxColor.fromHSL(Hue, Sat, Light, Alpha);
	}
	public static function fromString(str:String):Int
	{
		return cast flx.util.FlxColor.fromString(str);
	}
}
#end
