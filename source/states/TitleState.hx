package states;

import flixel.input.keyboard.FlxKey;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import haxe.Json;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import states.MenuState;

#if VIDEOS_ALLOWED
#if (hxCodec >= "3.0.0")
import hxcodec.flixel.FlxVideo as VideoHandler;
#elseif (hxCodec >= "2.6.1")
import hxcodec.VideoHandler as VideoHandler;
#elseif (hxCodec == "2.6.0")
import VideoHandler;
#else
import vlc.MP4Handler as VideoHandler;
#end
#end

class TitleState extends GameState
{
    public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
    public var initialized:Bool = false;
    public var transitioning:Bool = false;

    override public function create()
	{
        var title = new FlxText(0, 0, 0, "Ali Alafandy Game", 24);
        title.screenCenter(X);
        title.y = 140;
        add(title);

        var press = new FlxText(0, 0, 0, "Press Any Button", 12);
        press.screenCenter(X);
        press.y = 200;
        add(press);

        FlxG.sound.playMusic(Paths.music('themes/start_nice'));

		new FlxTimer().start(1, function(tmr:FlxTimer)
        {
            startVideo('alafandy_intro');
            trace('starting video...');
        });
    }

	public function startIntro()
	{
		var person = new FlxText(0, 0, 0, "Ali Alafandy", 24);
        person.screenCenter(X);
		person.color = 0xFF00000FF;
        person.y = 240;
        add(person);

		var t = new FlxText(0, 0, 0, "Present", 12);
        t.screenCenter(X);
        t.y = 480;
        add(t);

		new FlxTimer().start(1, function(tmr:FlxTimer)
        {
            skipIntro();
        });
	}

	var pressedAny:Array<FlxG> = [FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed];

    override public function update(elapsed:Float) {
        super.update(elapsed);

		if (initialized && !transitioning && skippedIntro)
        	if (pressedAny) {
				transitioning = true;
				new FlxTimer().start(1, function(tmr:FlxTimer)
        		{
            		GameState.switchState(new MenuState());
        		});
			}
        }

		if (initialized && pressedAny && !skippedIntro) {
			skipIntro();
		}
    }

	var skippedIntro:Bool = false;
	public function skipIntro()
	{
		if (!skippedIntro)
			skippedIntro = true;
	}

    public function startVideo(name:String)
    {
        #if VIDEOS_ALLOWED
        var filepath:String = Paths.video(name);
        #if sys
        if(!FileSystem.exists(filepath))
        #else
        if(!OpenFlAssets.exists(filepath))
        #end
        {
            FlxG.log.warn('Couldnt find video file: ' + name);
			startIntro();
			initialized = true;
            return;
        }
        var video:VideoHandler = new VideoHandler();
            #if (hxCodec >= "3.0.0")
            // Recent versions
            video.play(filepath);
            video.onEndReached.add(function()
            {
                video.dispose();
                startIntro();
                initialized = true;
                return;
            }, true);
            #else
            // Older versions
            video.playVideo(filepath);
            video.finishCallback = function()
			{
				startIntro();
				initialized = true;
                return;
            }
            #end
        #else
        FlxG.log.warn('Platform not supported!');
        return;
        #end
	}
}
