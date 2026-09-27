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
import openfl.utils.Assets as OpenFlAssets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import states.MenuState;

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;
import hxvlc.impl.Instance;
#end

class TitleState extends GameState
{
    public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
    public var initialized:Bool = false;
	// public var startIntro:Bool = false;

	#i
    var videoSprite:FlxVideoSprite;

    override public function create() {
        var title = new FlxText(0, 0, 0, "Ali Alafandy Game", 24);
        title.screenCenter(X);
        title.y = 140;
        add(title);

		var press = new FlxText(0, 0, 0, "", 12);
		press.screenCenter(X);
        press.y = 200;
        add(press);

		#if mobile
		press.text = "Touch On Screen";
		#else
        press.text = "Press Any Button";
		#end

        FlxG.sound.play(Paths.music('themes/start_nice'));

        new FlxTimer().start(1, function(tmr:FlxTimer)
        {
            startVideo('alafandy_intro');
            trace('starting video...');
        });
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        
        if (videoSprite != null)
        {
            if (FlxG.keys.justPressed.SPACE)
                videoSprite.togglePaused();
        }

        if (FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed) {
			FlxG.sound.play(Paths.sound('confirm_sound'));
            GameState.switchState(new MenuState());
        }
    }

    public function startVideo(name:String)
    {
		#if VIDEO_ALLOWED
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

        videoSprite = new FlxVideoSprite(0, 0);
        videoSprite.bitmap.onEndReached.add(function():Void
        {
            if (videoSprite != null)
            {
                remove(videoSprite);
                videoSprite.destroy();
                videoSprite = null;
            }
            initialized = true;
        });
        videoSprite.bitmap.onFormatSetup.add(function():Void
        {
            if (videoSprite.bitmap != null && videoSprite.bitmap.bitmapData != null)
            {
                final scale:Float = Math.min(FlxG.width / videoSprite.bitmap.bitmapData.width, FlxG.height / videoSprite.bitmap.bitmapData.height);

                videoSprite.setGraphicSize(videoSprite.bitmap.bitmapData.width * scale, videoSprite.bitmap.bitmapData.height * scale);
                videoSprite.updateHitbox();
                videoSprite.screenCenter();
            }
        });
        add(videoSprite);
        videoSprite.load(filepath);
		#end
    }
}
