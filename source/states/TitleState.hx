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
#end

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite as VideoHandler;
#end

class TitleState extends GameState
{
    public static var initialized:Bool = false;

    // Keep the sound hotkeys available to ClientPrefs across state transitions.
    public static var muteKeys:Array<FlxKey> = [];
    public static var volumeDownKeys:Array<FlxKey> = [];
    public static var volumeUpKeys:Array<FlxKey> = [];

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
            // FlxVideoSprite is the HaxeFlixel display wrapper. FlxVideo alone
            // is an OpenFL display object and is not rendered by FlxState.add().
            video = new VideoHandler();
            video.antialiasing = true;
            add(video);

            video.bitmap.onEndReached.add(function():Void
            {
                finishVideo();
                startIntro();
            }, true);

            video.bitmap.onFormatSetup.add(function():Void
            {
                if (video != null && video.bitmap != null && video.bitmap.bitmapData != null)
                {
                    video.setGraphicSize(FlxG.width, FlxG.height);
                    video.updateHitbox();
                    video.setPosition(0, 0);
                }
            });

            var loaded:Bool = video.load(filepath);
            FlxG.log.notice('[TitleState] Intro video load ' + (loaded ? 'succeeded' : 'failed') + ': ' + filepath);

            // Packaged builds may not expose embedded assets as ordinary files.
            // hxvlc accepts Bytes as a media source, so use the embedded asset
            // when the direct filesystem path cannot be opened.
            if (!loaded && OpenFlAssets.exists(filepath))
            {
                var videoBytes = OpenFlAssets.getBytes(filepath);
                if (videoBytes != null)
                    loaded = video.load(videoBytes);
            }

            if (loaded)
            {
                new FlxTimer().start(0.05, function(_:FlxTimer):Void
                {
                    if (video != null && !introStarted && !titleReady)
                    {
                        if (!video.play())
                        {
                            FlxG.log.warn('[TitleState] VLC could not start intro playback: ' + filepath);
                            finishVideo();
                            startIntro();
                        }
                    }
                });
            }
            else
            {
                FlxG.log.warn("Could not load intro video from path or embedded bytes: " + filepath);
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
            var oldVideo = video;
            video = null;
            remove(oldVideo, true);
            oldVideo.destroy();
        }
        #end
    }

    /**
     * Fade any FlxSprite-based UI element (including FlxText and image sprites)
     * without touching the intro video layer.
     */
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

        // Hold the credit briefly, then fade it away before showing the title.
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
