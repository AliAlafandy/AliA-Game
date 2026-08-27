package data.debug;

import flixel.FlxG;
import flixel.util.FlxStringUtil;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.system.System as OpenFlSystem;
import lime.system.System as LimeSystem;
import lime.ui.KeyCode;
import lime.app.Application;

#if cpp
#if windows
@:cppFileCode('#include <windows.h>')
#elseif (ios || mac)
@:cppFileCode('#include <mach-o/arch.h>')
#else
@:headerInclude('sys/utsname.h')
#end
#end
class FPSCounter extends TextField
{
	public var currentFPS(default, null):Int;
	public var minFPS(default, null):Int;
	public var maxFPS(default, null):Int;
	public var avgFPS(get, never):Float;

	public var frameTimeMs(default, null):Float;

	public var memoryMegas(get, never):Float;
	public var peakMemoryMegas(default, null):Float;

	public var _visible:Bool = true;
	public var updateInterval:Float = 500;

	public var os:String = '';
	public var engineVersion:String = '';

	@:noCompletion private var frameCount:Int;
	@:noCompletion private var elapsedSinceUpdate:Float;
	@:noCompletion private var fpsSum:Float;
	@:noCompletion private var fpsSamples:Int;
	@:noCompletion private var deltaTimeout:Float;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0xFFFFFFFF)
	{
		super();

		if (LimeSystem.platformName == LimeSystem.platformVersion || LimeSystem.platformVersion == null)
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end;
		else
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end + ' - ${LimeSystem.platformVersion}';

		engineVersion = '\nAli-A Game v' + Application.current.meta.get('version');

		positionFPS(x, y);

		currentFPS = 0;
		minFPS = 0;
		maxFPS = 0;
		frameTimeMs = 0;
		peakMemoryMegas = 0;

		frameCount = 0;
		elapsedSinceUpdate = 0;
		fpsSum = 0;
		fpsSamples = 0;
		deltaTimeout = 0;

		selectable = false;
		mouseEnabled = false;
		multiline = true;
		width = FlxG.width;
		defaultTextFormat = new TextFormat("_sans", 14, color);
		text = "FPS: ";

		visible = true;
	}

	private override function __enterFrame(deltaTime:Float):Void
	{
		frameCount++;
		elapsedSinceUpdate += deltaTime;
		frameTimeMs = deltaTime;

		final mem:Float = memoryMegas;
		if (mem > peakMemoryMegas)
			peakMemoryMegas = mem;

		if (elapsedSinceUpdate < updateInterval)
			return;

		currentFPS = Math.round(frameCount / (elapsedSinceUpdate / 1000));
		currentFPS = currentFPS > FlxG.updateFramerate ? FlxG.updateFramerate : currentFPS;

		if (minFPS == 0 || currentFPS < minFPS)
			minFPS = currentFPS;
		if (currentFPS > maxFPS)
			maxFPS = currentFPS;

		fpsSum += currentFPS;
		fpsSamples++;

		frameCount = 0;
		elapsedSinceUpdate = 0;

		if (visible)
			updateText();
	}

	public dynamic function updateText():Void
	{
		text =
			'FPS: $currentFPS (min $minFPS / max $maxFPS / avg ${Math.round(avgFPS)})' +
			'\nFrame: ${FlxStringUtil.formatBytes(0) != null ? Math.round(frameTimeMs * 100) / 100 : frameTimeMs}ms' +
			'\nMemory: ${FlxStringUtil.formatBytes(memoryMegas)} (peak ${FlxStringUtil.formatBytes(peakMemoryMegas)})' +
			os +
			engineVersion;

		textColor = 0xFFFFFFFF;
		if (currentFPS < FlxG.drawFramerate * 0.5)
			textColor = 0xFFFF0000;
		else if (currentFPS < FlxG.drawFramerate * 0.8)
			textColor = 0xFFFFFF00;
	}

	public function resetStats():Void
	{
		minFPS = 0;
		maxFPS = 0;
		fpsSum = 0;
		fpsSamples = 0;
		peakMemoryMegas = memoryMegas;
	}

	public function toggle():Void
	{
		visible = !visible;
	}

	inline function get_avgFPS():Float
		return fpsSamples > 0 ? fpsSum / fpsSamples : currentFPS;

	inline function get_memoryMegas():Float
		return cast(OpenFlSystem.totalMemory, UInt);

	override function get_visible():Bool
	{
		return _visible;
	}

	override function set_visible(value:Bool):Bool
	{
		if (_visible == value) return value;
		_visible = value;
		
		if (!value)
			text = "";
		else
			updateText();
			
		return super.set_visible(value);
	}

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1)
	{
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
		x = FlxG.game.x + X;
		y = FlxG.game.y + Y;
	}

	#if cpp
	#if windows
	@:functionCode('
		SYSTEM_INFO osInfo;

		GetSystemInfo(&osInfo);

		switch(osInfo.wProcessorArchitecture)
		{
			case 9:
				return ::String("x86_64");
			case 5:
				return ::String("ARM");
			case 12:
				return ::String("ARM64");
			case 6:
				return ::String("IA-64");
			case 0:
				return ::String("x86");
			default:
				return ::String("Unknown");
		}
	')
	#elseif (ios || mac)
	@:functionCode('
		const NXArchInfo *archInfo = NXGetLocalArchInfo();
    	return ::String(archInfo == NULL ? "Unknown" : archInfo->name);
	')
	#else
	@:functionCode('
		struct utsname osInfo{};
		uname(&osInfo);
		return ::String(osInfo.machine);
	')
	#end
	@:noCompletion
	private function getArch():String
	{
		return "Unknown";
	}
	#end
}
