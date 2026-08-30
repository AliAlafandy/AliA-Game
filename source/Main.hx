import data.debug.FPSCounter;
import data.debug.CrashHandler;

import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;
import haxe.io.Path;
import haxe.Timer;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.display.StageScaleMode;
import lime.system.System as LimeSystem;
import lime.app.Application;
import openfl.events.KeyboardEvent;

#if mobile
import mobile.StorageUtil;
#end

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import online.MultiPlayer;

import states.TitleState;

#if linux
import lime.graphics.Image;

@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end

typedef BootConfig =
{
	width:Int,
	height:Int,
	initialState:Class<FlxState>,
	zoom:Float,
	framerate:Int,
	skipSplash:Bool,
	startFullscreen:Bool
}

class Main extends Sprite
{
	private static inline var DEFAULT_WIDTH:Int = 1280;
	private static inline var DEFAULT_HEIGHT:Int = 720;
	private static inline var RESIZE_DEBOUNCE:Float = 0.15;

	var game:BootConfig = {
		width: DEFAULT_WIDTH,
		height: DEFAULT_HEIGHT,
		initialState: TitleState,
		zoom: -1.0,
		framerate: 60,
		skipSplash: true,
		startFullscreen: false
	};

	public static var fpsVar:FPSCounter;
	public static var safeMode:Bool = false;
	public static var bootSucceeded:Bool = false;

	#if mobile
	public static final platform:String = "Phones";
	#else
	public static final platform:String = "PCs";
	#end

	private var resizeTimer:Timer;

	public static function main():Void
	{
		Lib.current.addChild(new Main());

		#if cpp
		cpp.NativeGc.enable(true);
		cpp.NativeGc.run(true);
		#end
	}

	public function new()
	{
		super();

		parseArguments();

		#if mobile
		MobileData.init();
		#if android
		StorageUtil.requestPermissions();
		#end
		#end

		CrashHandler.init();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function parseArguments():Void
	{
		#if sys
		var args = Sys.args();

		for (arg in args)
		{
			if (arg == "--safe-mode")
				safeMode = true;

			if (arg.startsWith("--width="))
				game.width = Std.parseInt(arg.substr(8));

			if (arg.startsWith("--height="))
				game.height = Std.parseInt(arg.substr(9));

			if (arg == "--fullscreen")
				game.startFullscreen = true;

			if (arg == "--no-splash")
				game.skipSplash = true;
		}

		if (game.width <= 0) game.width = DEFAULT_WIDTH;
		if (game.height <= 0) game.height = DEFAULT_HEIGHT;
		#end
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		try
		{
			setupGame();
			bootSucceeded = true;
		}
		catch (e:Dynamic)
		{
			handleBootFailure(e);
		}
	}

	private function handleBootFailure(error:Dynamic):Void
	{
		#if sys
		try
		{
			var log = 'Boot failure: ${Std.string(error)}\n${haxe.CallStack.toString(haxe.CallStack.exceptionStack())}';
			File.saveContent('crash_boot.log', log);
		}
		catch (e:Dynamic) {}
		#end

		if (!safeMode)
		{
			safeMode = true;
			try
			{
				setupGame();
				bootSucceeded = true;
			}
			catch (fallbackError:Dynamic)
			{
				LimeSystem.exit(1);
			}
		}
		else
		{
			LimeSystem.exit(1);
		}
	}

	private function setupGame():Void
	{
		resolveWindowScale();

		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.load();
		#end

		if (MultiPlayer.instance == null)
			new MultiPlayer();

		var initialState = safeMode ? TitleState : game.initialState;

		addChild(new FlxGame(
			game.width,
			game.height,
			initialState,
			#if (flixel < "5.0.0") game.zoom, #end
			game.framerate,
			game.framerate,
			game.skipSplash,
			game.startFullscreen
		));

		setupDebugOverlay();
		setupStageProperties();
		setupPlatformFlags();
		setupEventListeners();
	}

	private function resolveWindowScale():Void
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
	}

	private function setupDebugOverlay():Void
	{
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		fpsVar.visible = ClientPrefs.data.showFPS;
	}

	private function setupStageProperties():Void
	{
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		#if linux
		try
		{
			var icon = Image.fromFile("icon.png");
			Lib.current.stage.window.setIcon(icon);
		}
		catch (e:Dynamic) {}
		#end
	}

	private function setupPlatformFlags():Void
	{
		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		#if DISCORD_ALLOWED
		if (!safeMode)
			DiscordClient.prepare();
		#end

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		#if mobile
		LimeSystem.allowScreenTimeout = ClientPrefs.data.screensaver;
		#end
	}

	private function setupEventListeners():Void
	{
		#if desktop
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, toggleFullScreen);
		FlxG.stage.addEventListener(FocusEvent.FOCUS_OUT, onWindowBlur);
		FlxG.stage.addEventListener(FocusEvent.FOCUS_IN, onWindowFocus);
		#end

		Lib.current.stage.addEventListener(Event.RESIZE, onStageResize);

		FlxG.signals.gameResized.add(onGameResized);

		Lib.current.addEventListener(Event.DEACTIVATE, onApplicationDeactivate);
		Lib.current.addEventListener(Event.ACTIVATE, onApplicationActivate);
	}

	private function onStageResize(event:Event):Void
	{
		if (resizeTimer != null)
			resizeTimer.stop();

		resizeTimer = Timer.delay(commitResize, Math.round(RESIZE_DEBOUNCE * 1000));
	}

	private function commitResize():Void
	{
		if (fpsVar != null)
			fpsVar.positionFPS(10, 3, Math.min(Lib.current.stage.stageWidth / FlxG.width, Lib.current.stage.stageHeight / FlxG.height));
	}

	private function onGameResized(w:Int, h:Int):Void
	{
		if (fpsVar != null)
			fpsVar.positionFPS(10, 3, Math.min(Lib.current.stage.stageWidth / FlxG.width, Lib.current.stage.stageHeight / FlxG.height));

		if (FlxG.cameras != null)
		{
			for (cam in FlxG.cameras.list)
			{
				if (cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			}
		}

		if (FlxG.game != null)
			resetSpriteCache(FlxG.game);
	}

	private function onWindowBlur(event:FocusEvent):Void
	{
		#if MULTIPLAYER_ALLOWED
		if (MultiPlayer.instance != null && MultiPlayer.instance.isConnected())
			MultiPlayer.instance.sendPlayerUpdate(0, 0, "away");
		#end
	}

	private function onWindowFocus(event:FocusEvent):Void
	{
	}

	private function onApplicationDeactivate(event:Event):Void
	{
		#if cpp
		cpp.NativeGc.run(false);
		#end
	}

	private function onApplicationActivate(event:Event):Void
	{
	}

	static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	function toggleFullScreen(event:KeyboardEvent):Void
	{
		if (Controls.instance.justReleased('fullscreen'))
			FlxG.fullscreen = !FlxG.fullscreen;
	}
}
