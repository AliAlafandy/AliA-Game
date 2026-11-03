package states;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import states.MenuState;
import openfl.utils.Assets as OpenFlAssets;

#if sys
import sys.FileSystem;
#end

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideo as VideoHandler;
#end

class TitleState extends GameState
{
    public static var initialized:Bool = false;

    private var introStarted:Bool = false;
    private var titleReady:Bool = false;
    private var transitioning:Bool = false;
    private var skippedIntro:Bool = false;

    #if VIDEOS_ALLOWED
    private var video:VideoHandler;
    #end

    override public function create():Void
    {
        super.create();

        Paths.clearStoredMemory();
        ClientPrefs.loadPrefs();

        // Do not replay the publisher/video intro when returning to this state.
        if (initialized)
            startTitleScreen();
        else
            new FlxTimer().start(0.25, function(_:FlxTimer):Void // 1
            {
                startVideo("alafandy_intro");
            });
    }

    private function hasInput():Bool
    {
        var pressed:Bool = FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed;
        #if FLX_TOUCH
        for (touch in FlxG.touches.list)
            if (touch.justPressed) pressed = true;
        #end
        return pressed;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!titleReady && !introStarted && hasInput())
        {
            // Allow the player to skip the video without leaving the title state.
            finishVideo();
            startIntro();
            return;
        }

        if (titleReady && !transitioning && hasInput())
        {
            transitioning = true;
            FlxG.sound.play(Paths.sound("confirm_sound"));
            new FlxTimer().start(0.35, function(_:FlxTimer):Void // 1
            {
                GameState.switchState(new MenuState());
            });
        }
    }

    public function startVideo(name:String):Void
    {
        #if VIDEOS_ALLOWED
        if (introStarted || titleReady) return;

        var filepath:String = Paths.video(name);
        var exists:Bool = false;

        #if sys
        exists = FileSystem.exists(filepath);
        #end
        if (!exists) exists = OpenFlAssets.exists(filepath);

        if (!exists)
        {
            FlxG.log.warn("Could not find intro video: " + filepath);
            startIntro();
            return;
        }

        try
        {
            video = new VideoHandler();

            video.onEndReached.add(function():Void
            {
                finishVideo();
                startIntro();
            }, true);

            // hxvlc 2.x uses load() + play(); the older MP4Handler API
            // (playVideo/finishCallback) is not part of this dependency.
            if (video.load(filepath))
                video.play();
            else
            {
                FlxG.log.warn("Could not load intro video: " + filepath);
                finishVideo();
                startIntro();
            }
        }
        catch (e:Dynamic)
        {
            FlxG.log.error("Could not play intro video: " + Std.string(e));
            finishVideo();
            startIntro();
        }
        #else
        startIntro();
        #end
    }

    private function finishVideo():Void
    {
        #if VIDEOS_ALLOWED
        if (video != null)
        {
            video.dispose();
            video = null;
        }
        #end
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

        var present = new FlxText(0, 0, 0, "PRESENTS", 14);
        present.screenCenter(X);
        present.y = person.y + 48;
        add(present);

        new FlxTimer().start(1.4, function(_:FlxTimer):Void
        {
            if (this != null) startTitleScreen();
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

        FlxG.sound.play(Paths.music("themes/start_nice"), 1, false);
        Paths.clearUnusedMemory();
    }

    override public function destroy():Void
    {
        finishVideo();
        super.destroy();
    }
}
