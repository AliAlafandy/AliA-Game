package data.scripts;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.group.FlxGroup.FlxTypedGroup;
#if mobile
import mobile.StorageUtil;
#end

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
		set('FlxG', FlxG);
		set('FlxMath', FlxMath);
		set('FlxSprite', FlxSprite);
		set('FlxCamera', FlxCamera);
		set('FlxTimer', FlxTimer);
		set('FlxTween', FlxTween);
		set('FlxEase', FlxEase);
		set('PlayState', PlayState);
		set('Paths', Paths);
		#if mobile
		set('StorageUtil', StorageUtil);
		#end
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

		// Safe utility bindings
		set('Reflect', Reflect);
		set('getPropertySafe', function(obj:Dynamic, field:String, ?defaultValue:Dynamic = null):Dynamic {
			if (obj != null && Reflect.hasField(obj, field)) {
				var val = Reflect.field(obj, field);
				return val != null ? val : defaultValue;
			}
			return defaultValue;
		});

		// Functions & Variables
		set('setVar', function(name:String, value:Dynamic) {
			if (PlayState.instance != null && Reflect.hasField(PlayState.instance, 'variables')) {
				PlayState.instance.variables.set(name, value);
			}
			return value;
		});
		set('getVar', function(name:String) {
			var result:Dynamic = null;
			if (PlayState.instance != null && Reflect.hasField(PlayState.instance, 'variables')) {
				if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			}
			return result;
		});
		set('removeVar', function(name:String)
		{
			if (PlayState.instance != null && Reflect.hasField(PlayState.instance, 'variables')) {
				if(PlayState.instance.variables.exists(name))
				{
					PlayState.instance.variables.remove(name);
					return true;
				}
			}
			return false;
		});
		set('debugPrint', function(text:String, ?color:FlxColor = null) {
			if(color == null) color = FlxColor.WHITE;
			if (PlayState.instance != null && Reflect.hasField(PlayState.instance, 'addTextToDebug')) {
				PlayState.instance.addTextToDebug(text, color);
			} else {
				trace(text);
			}
		});

		// Keyboard & Gamepads
		set('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		set('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		set('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

		set('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
		set('anyGamepadPressed', function(name:String) FlxG.gamepads.anyPressed(name));
		set('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));

		set('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getXAxis(leftStick ? FlxGamepadInputID.LEFT_ANALOG_STICK : FlxGamepadInputID.RIGHT_ANALOG_STICK);
		});
		set('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getYAxis(leftStick ? FlxGamepadInputID.LEFT_ANALOG_STICK : FlxGamepadInputID.RIGHT_ANALOG_STICK);
		});
		set('gamepadJustPressed', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justPressed, name) == true;
		});
		set('gamepadPressed', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.pressed, name) == true;
		});
		set('gamepadReleased', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
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
				if(PlayState.instance != null && Reflect.hasField(PlayState.instance, 'addTextToDebug')) PlayState.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
				else trace('$origin - $msg');
			}
		});
		set('this', this);
		set('game', FlxG.state);
		
		set('add', FlxG.state.add);
		set('insert', FlxG.state.insert);
		set('remove', FlxG.state.remove);

		if(PlayState.instance == FlxG.state)
		{
			var excludeList:Array<String> = Reflect.field(PlayState.instance, 'instancesExclude');
			if (excludeList == null) excludeList = [];
			setSpecialObject(PlayState.instance, false, excludeList);
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
			if (PlayState.instance != null && Reflect.hasField(PlayState.instance, 'addTextToDebug'))
				PlayState.instance.addTextToDebug(origin + ' - No HScript function named: $funcToRun', FlxColor.RED);
			return null;
		}

		final callValue = call(funcToRun, funcArgs);
		if (!callValue.succeeded)
		{
			final e = callValue.exceptions[0];
			if (e != null) {
				var msg:String = e.toString();
				if (PlayState.instance != null && Reflect.hasField(PlayState.instance, 'addTextToDebug'))
					PlayState.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
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
#end
