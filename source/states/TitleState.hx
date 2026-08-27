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
    //public var startIntro:Bool = false;

    override public function create() {
        var title = new FlxText(0, 0, 0, "Ali Alafandy Game", 24);
        title.screenCenter(X);
        title.y = 140;
        add(title);

        var press = new FlxText(0, 0, 0, "Press Any Button", 12);
        press.screenCenter(X);
        press.y = 200;
        add(press);

        FlxG.sound.playMusic(Paths.music('themes/start_nice'));
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if (FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed) {   
			startVideo('alafandy_intro');
			trace('starting video...');
        }
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
            return;
        }
        var video:VideoHandler = new VideoHandler();
            #if (hxCodec >= "3.0.0")
            // Recent versions
            video.play(filepath);
            video.onEndReached.add(function()
            {
                video.dispose();
                //startIntro();
                initialized = true;
				GameState.switchState(new MenuState());
                return;
            }, true);
            #else
            // Older versions
            video.playVideo(filepath);
            video.finishCallback = function()
            {
				GameState.switchState(new MenuState());
                return;
            }
            #end
        #else
        FlxG.log.warn('Platform not supported!');
        return;
        #end
	}
}
