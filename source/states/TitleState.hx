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

#if sys
import sys.FileSystem;
import sys.io.File;
#end
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
        var fileName:String = Paths.video(name);
        trace('[TitleState] startVideo("$name") -> $fileName');

        #if VIDEOS_ALLOWED
        trace('[TitleState] VIDEOS_ALLOWED: ON');
        #else
        trace('[TitleState] VIDEOS_ALLOWED: OFF -> video code compiled out, fix Project.xml');
        #end
        #if hxvlc
        trace('[TitleState] hxvlc: ON');
        #else
        trace('[TitleState] hxvlc: OFF -> hxvlc haxelib not linked');
        #end
        #if sys
        trace('[TitleState] exists on disk: ' + FileSystem.exists(fileName));
        #end
        trace('[TitleState] exists as asset: ' + OpenFlAssets.exists(fileName));

        #if VIDEOS_ALLOWED
        if (introStarted || titleReady || videoCutscene != null)
        {
            trace('[TitleState] aborted: introStarted=$introStarted titleReady=$titleReady');
            return;
        }

        var source:String = resolveVideoSource(fileName);
        trace('[TitleState] VLC source: $source');
        if (source == null)
        {
            trace('[TitleState] no playable source -> skipping video');
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

    private function resolveVideoSource(fileName:String):String
    {
        #if sys
        if (FileSystem.exists(fileName)) return fileName;
        #end

        if (!OpenFlAssets.exists(fileName)) return null;

        #if sys
        try
        {
            var bytes = OpenFlAssets.getBytes(fileName);
            if (bytes == null || bytes.length == 0) return null;

            var dir:String = System.applicationStorageDirectory;
            if (!FileSystem.exists(dir)) FileSystem.createDirectory(dir);

            var cachePath:String = haxe.io.Path.join([dir, haxe.io.Path.withoutDirectory(fileName)]);
            if (!FileSystem.exists(cachePath) || FileSystem.stat(cachePath).size != bytes.length)
                File.saveBytes(cachePath, bytes);

            FlxG.log.notice("[TitleState] Intro cached at: " + cachePath);
            return cachePath;
        }
        catch (e:Dynamic)
        {
            FlxG.log.error("[TitleState] Could not cache intro video: " + Std.string(e));
            return null;
        }
        #else
        return null;
        #end
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
