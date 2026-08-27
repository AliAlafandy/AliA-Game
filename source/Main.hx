import data.debug.FPSCounter;
import data.debug.CrashHandler;
import data.audio.Audio;

import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxG;
import flixel.FlxState;
import haxe.io.Path;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.UncaughtErrorEvent;
import lime.system.System as LimeSystem;
import lime.app.Application;

#if mobile
import mobile.StorageUtil;
#end

import states.TitleState;

#if linux
import lime.graphics.Image;

@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end

class Main extends Sprite {

	static inline var WINDOW_WIDTH:Int = 1280;
	static inline var WINDOW_HEIGHT:Int = 720;
	static inline var TARGET_FRAMERATE:Int = 60;

	var game = {
		width: WINDOW_WIDTH,
		height: WINDOW_HEIGHT,
		initialState: TitleState,
		zoom: -1.0,
		framerate: TARGET_FRAMERATE,
		skipSplash: true,
		startFullscreen: false
	};

	public static var fpsVar:FPSCounter;

	#if mobile
	public static final platform:String = "Phones";
	#else
	public static final platform:String = "PCs";
	#end

	public static function main():Void
	{
		Lib.current.addChild(new Main());
		#if cpp
		cpp.NativeGc.enable(true);
		cpp.NativeGc.run(true);
		#end
	}

	public function new() {
		super();

		#if mobile
		MobileData.init();
		#if android
		StorageUtil.requestPermissions();
		#end
		#end

		CrashHandler.init();
		setupUncaughtErrorHandling();
		Audio.init();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?e:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupUncaughtErrorHandling():Void
	{
		#if !flash
		if (loaderInfo != null && loaderInfo.uncaughtErrorEvents != null)
		{
			loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		}
		#end
	}

	private function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		var message = "Unknown error";

		if (Std.isOfType(e.error, Error))
		{
			message = cast(e.error, Error).message;
		}
		else
		{
			message = Std.string(e.error);
		}

		CrashHandler.report(message);
		e.preventDefault();
	}

	private function setupGame():Void
	{
		#if (openfl <= "9.2.0")
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}
		#else
		if (game.zoom == -1.0)
			game.zoom = 1.0;
		#end

		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.load();
		#end

		addChild(new FlxGame(game.width, game.height, game.initialState,
			#if (flixel < "5.0.0") game.zoom, #end
			game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		fpsVar.visible = ClientPrefs.data.showFPS;

		#if linux
		setupLinuxIcon();
		#end

		#if desktop
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, toggleFullScreen);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		#if mobile
		LimeSystem.allowScreenTimeout = ClientPrefs.data.screensaver;
		#end

		FlxG.signals.gameResized.add(onGameResized);
	}

	#if linux
	private function setupLinuxIcon():Void
	{
		try
		{
			var icon = Image.fromFile("icon.png");
			Lib.current.stage.window.setIcon(icon);
		}
		catch (e:Dynamic) {}
	}
	#end

	private function onGameResized(w:Int, h:Int):Void
	{
		if (fpsVar != null)
		{
			var scale = Math.min(Lib.current.stage.stageWidth / FlxG.width, Lib.current.stage.stageHeight / FlxG.height);
			fpsVar.positionFPS(10, 3, scale);
		}

		if (FlxG.cameras != null)
		{
			for (cam in FlxG.cameras.list)
			{
				if (cam != null && cam.filters != null)
				{
					resetSpriteCache(cam.flashSprite);
				}
			}
		}

		if (FlxG.game != null)
		{
			resetSpriteCache(FlxG.game);
		}
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	function toggleFullScreen(event:KeyboardEvent):Void
	{
		if (Controls.instance.justReleased('fullscreen'))
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}
	}
}
