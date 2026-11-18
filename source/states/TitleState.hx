package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import states.MenuState;
import openfl.utils.Assets as OpenFlAssets;
import lime.system.System;

#if VIDEOS_ALLOWED
import data.objects.VideoSprite;
#end

class TitleState extends GameState
{
    public static var initialized:Bool = false;

    public static var muteKeys:Array<FlxKey> = [];
    public static var volumeDownKeys:Array<FlxKey> = [];
    public static var volumeUpKeys:Array<FlxKey> = [];

    private var introStarted:Bool = false;
    private var titleReady:Bool = false;
    private var transitioning:Bool = false;

    #if VIDEOS_ALLOWED
    public var videoCutscene:VideoSprite = null;
    #end

    override public function create():Void
    {
        super.create();

		#if VIDEOS_ALLOWED
        if (videoCutscene != null)
        {
            FlxG.camera.stopFade();
            FlxG.camera.alpha = 1;
        }
        #end

        Paths.clearStoredMemory();
        ClientPrefs.loadPrefs();

        if (initialized)
            startTitleScreen();
        else
            new FlxTimer().start(0.25, function(_:FlxTimer):Void
            {
                startVideo("alafandy_intro");
            });
    }

    private function hasInput():Bool
    {
        var pressed:Bool = FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed;
        #if FLX_TOUCH
        if (!pressed)
            for (touch in FlxG.touches.list)
                if (touch.justPressed) { pressed = true; break; }
        #end
        return pressed;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!titleReady && !introStarted && hasInput())
        {
            finishVideo();
            startIntro();
            return;
        }

        if (titleReady && !transitioning && hasInput())
        {
            transitioning = true;
            FlxG.sound.play(Paths.sound("confirm_sound"));
            new FlxTimer().start(0.35, function(_:FlxTimer):Void
            {
                GameState.switchState(new MenuState());
            });
        }
    }

    public function startVideo(name:String, canSkip:Bool = true, loop:Bool = false):Void
	{
		#if VIDEOS_ALLOWED
		if (introStarted || titleReady || videoCutscene != null) return;

		var source:String = Paths.videoFile(name);
		trace('[TitleState] VLC source: $source');
		if (source == null)
		{
			trace('[TitleState] video assets: ' + OpenFlAssets.list().filter(
				f -> f.toLowerCase().indexOf(name.toLowerCase()) != -1));
			startIntro();
			return;
		}

		try
		{
			videoCutscene = new VideoSprite(source, false, canSkip, loop);
            videoCutscene.finishCallback = onVideoEnd;
            videoCutscene.onSkip = onVideoEnd;
            add(videoCutscene);

            var bmp = videoCutscene.videoSprite.bitmap;
            bmp.onOpening.add(function():Void { trace('[TitleState] VLC opening'); });
            bmp.onPlaying.add(function():Void { trace('[TitleState] VLC playing'); });
            bmp.onEncounteredError.add(function(msg:String):Void
            {
                trace('[TitleState] VLC ERROR: ' + msg);
                finishVideo();
                startIntro();
            });

            new FlxTimer().start(0.05, function(_:FlxTimer):Void
            {
                if (videoCutscene == null || introStarted || titleReady) return;
                var ok:Bool = videoCutscene.videoSprite.play();
                trace('[TitleState] play() = $ok');
                if (!ok) { finishVideo(); startIntro(); }
            });

            new FlxTimer().start(3, function(_:FlxTimer):Void
            {
                if (videoCutscene == null || introStarted || titleReady) return;
                trace('[TitleState] watchdog isPlaying=' + videoCutscene.videoSprite.bitmap.isPlaying);
                if (!videoCutscene.videoSprite.bitmap.isPlaying) { finishVideo(); startIntro(); }
            });
        }
        catch (e:Dynamic)
        {
            trace('[TitleState] EXCEPTION: ' + Std.string(e));
            finishVideo();
            startIntro();
        }
        #else
        startIntro();
        #end
    }

    #if VIDEOS_ALLOWED
    private function onVideoEnd():Void
    {
        videoCutscene = null;
        startIntro();
    }
    #end

    private function finishVideo():Void
    {
        #if VIDEOS_ALLOWED
        if (videoCutscene != null)
        {
            var old:VideoSprite = videoCutscene;
            videoCutscene = null;
            old.finishCallback = null;
            old.onSkip = null;
            if (old.videoSprite != null) old.videoSprite.stop();
            remove(old, true);
        }
        #end
    }

    private function fadeInElement(target:FlxSprite, duration:Float = 0.7):Void
    {
        if (target == null) return;
        target.alpha = 0;
        FlxTween.tween(target, {alpha: 1}, duration, {ease: FlxEase.quadOut});
    }

    public function startIntro():Void
    {
        if (introStarted || titleReady) return;
        introStarted = true;

        var person = new FlxText(0, 0, 0, "Ali Alafandy", 24);
        person.screenCenter(X);
        person.color = FlxColor.BLUE;
        person.y = FlxG.height * 0.36;
        add(person);
        fadeInElement(person, 0.75);

        var present = new FlxText(0, 0, 0, "PRESENTS", 14);
        present.screenCenter(X);
        present.y = person.y + 48;
        add(present);
        fadeInElement(present, 0.75);

        new FlxTimer().start(1.55, function(_:FlxTimer):Void
        {
            FlxTween.tween(person, {alpha: 0}, 0.45, {ease: FlxEase.quadIn});
            FlxTween.tween(present, {alpha: 0}, 0.45, {
                ease: FlxEase.quadIn,
                onComplete: function(_:FlxTween):Void
                {
                    if (!titleReady) startTitleScreen();
                }
            });
        });
    }

    private function startTitleScreen():Void
    {
        if (titleReady) return;

        initialized = true;
        introStarted = true;
        titleReady = true;

        var title = new FlxText(0, 0, 0, "Ali Alafandy Game", 28);
        title.screenCenter(X);
        title.y = FlxG.height * 0.34;
        add(title);
        fadeInElement(title, 0.85);

        var press = new FlxText(0, 0, FlxG.width, "", 16);
        press.screenCenter(X);
        press.y = title.y + 64;
        #if mobile
        press.text = "TOUCH TO START";
        #else
        press.text = "PRESS ANY BUTTON";
        #end
        press.alignment = CENTER;
        add(press);
        new FlxTimer().start(0.25, function(_:FlxTimer):Void
        {
            if (press != null) fadeInElement(press, 0.65);
        });

        FlxG.sound.play(Paths.music("themes/start_nice"), 1, false);
        Paths.clearUnusedMemory();
    }

    override public function destroy():Void
    {
        finishVideo();
        super.destroy();
    }
}
