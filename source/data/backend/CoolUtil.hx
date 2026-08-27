package data.backend;

import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class CoolUtil
{
	inline public static function quantize(f:Float, snap:Float):Float
	{
		var m:Float = Math.fround(f * snap);
		return (m / snap);
	}

	inline public static function capitalize(text:String):String
	{
		if (text == null || text.length == 0) return text;
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;

		#if (sys && MODS_ALLOWED)
		var formatted:Array<String> = path.split(':');
		var resolvedPath:String = formatted[formatted.length - 1];
		if (FileSystem.exists(resolvedPath)) daList = File.getContent(resolvedPath);
		#else
		if (Assets.exists(path)) daList = Assets.getText(path);
		#end

		return daList != null ? listFromString(daList) : [];
	}

	public static function colorFromString(rawColor:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(rawColor).join('').trim();

		if (color.startsWith('0x')) color = color.substring(2);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if (colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = string.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1)
			return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;

		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = new Map();

		sprite.pixels.lock();

		for (col in 0...sprite.frameWidth) {
			for (row in 0...sprite.frameHeight) {
				var pixel:Int = sprite.pixels.getPixel32(col, row);
				var alpha:Int = (pixel >>> 24) & 0xFF;

				if (alpha == 0) continue;

				if (countByColor.exists(pixel))
					countByColor.set(pixel, countByColor.get(pixel) + 1);
				else
					countByColor.set(pixel, 1);
			}
		}

		sprite.pixels.unlock();

		var maxCount:Int = 0;
		var maxKey:Int = 0;
		countByColor.remove(FlxColor.BLACK);

		for (key in countByColor.keys()) {
			var count = countByColor.get(key);
			if (count >= maxCount) {
				maxCount = count;
				maxKey = key;
			}
		}

		return maxKey;
	}

	inline public static function numberArray(max:Int, ?min:Int = 0):Array<Int>
	{
		var result:Array<Int> = [];
		for (i in min...max) result.push(i);
		return result;
	}

	inline public static function browserLoad(site:String):Void
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	public static function openFolder(folder:String, absolute:Bool = false):Void
	{
		#if sys
		var target:String = absolute ? folder : Sys.getCwd() + folder;

		#if windows
		target = target.replace('/', '\\');
		#end

		if (target.endsWith('/') || target.endsWith('\\'))
			target = target.substr(0, target.length - 1);

		#if linux
		var command:String = '/usr/bin/xdg-open';
		#else
		var command:String = 'explorer.exe';
		#end

		Sys.command(command, [target]);
		#else
		FlxG.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String
	{
		final company:String = FlxG.stage.application.meta.get('company');
		return '${company}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
	}

	public static function setTextBorderFromString(text:FlxText, border:String):Void
	{
		switch (border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}

	public static function showPopUp(message:String, title:String):Void
	{
		#if android
		AndroidTools.showAlertDialog(title, message, {name: "OK", func: null}, null);
		#else
		FlxG.stage.window.alert(message, title);
		#end
	}
}
