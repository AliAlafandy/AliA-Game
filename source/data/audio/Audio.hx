package data.audio;

import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.util.FlxTimer;

class Audio {

    static inline var SAVE_KEY:String = "audioSettings";

    public static var musicVolume(default, set):Float = 0.7;
    public static var sfxVolume(default, set):Float = 1.0;

    static var currentMusicId:String = null;
    static var sfxCache:Map<String, FlxSound> = new Map();
    static var fadeTimer:FlxTimer;

    public static function init():Void {
        load();
    }

    public static function playMusic(id:String, path:String, ?loop:Bool = true, ?fadeInTime:Float = 0):Void {
        if (currentMusicId == id && FlxG.sound.music != null && FlxG.sound.music.playing) {
            return;
        }

        currentMusicId = id;

        FlxG.sound.playMusic(path, musicVolume, loop);

        if (fadeInTime > 0 && FlxG.sound.music != null) {
            FlxG.sound.music.volume = 0;
            FlxG.sound.music.fadeIn(fadeInTime, 0, musicVolume);
        }
    }

    public static function stopMusic(?fadeOutTime:Float = 0):Void {
        if (FlxG.sound.music == null) return;

        currentMusicId = null;

        if (fadeOutTime > 0) {
            FlxG.sound.music.fadeOut(fadeOutTime, 0, function(_) {
                if (FlxG.sound.music != null) FlxG.sound.music.stop();
            });
        } else {
            FlxG.sound.music.stop();
        }
    }

    public static function pauseMusic():Void {
        if (FlxG.sound.music != null) FlxG.sound.music.pause();
    }

    public static function resumeMusic():Void {
        if (FlxG.sound.music != null) FlxG.sound.music.resume();
    }

    public static function crossfadeTo(id:String, path:String, ?loop:Bool = true, duration:Float = 1.0):Void {
        if (currentMusicId == id) return;

        var oldMusic = FlxG.sound.music;
        currentMusicId = id;

        if (oldMusic != null && oldMusic.playing) {
            oldMusic.fadeOut(duration, 0, function(_) {
                oldMusic.stop();
            });
        }

        var newTrack = FlxG.sound.load(path, 0, loop);
        newTrack.play();
        newTrack.fadeIn(duration, 0, musicVolume);
        FlxG.sound.music = newTrack;
    }

    public static function playSfx(id:String, path:String, ?volume:Float = 1.0):Void {
        var sound = sfxCache.get(id);

        if (sound == null) {
            sound = FlxG.sound.load(path);
            sfxCache.set(id, sound);
        }

        sound.volume = sfxVolume * volume;
        sound.play(true);
    }

    public static function preloadSfx(id:String, path:String):Void {
        if (sfxCache.exists(id)) return;
        sfxCache.set(id, FlxG.sound.load(path));
    }

    public static function clearSfxCache():Void {
        for (sound in sfxCache) {
            sound.destroy();
        }
        sfxCache.clear();
    }

    static function set_musicVolume(value:Float):Float {
        musicVolume = clampVolume(value);
        if (FlxG.sound.music != null) {
            FlxG.sound.music.volume = musicVolume;
        }
        save();
        return musicVolume;
    }

    static function set_sfxVolume(value:Float):Float {
        sfxVolume = clampVolume(value);
        save();
        return sfxVolume;
    }

    static function clampVolume(value:Float):Float {
        return Math.max(0, Math.min(1, value));
    }

    static function save():Void {
        FlxG.save.data.musicVolume = musicVolume;
        FlxG.save.data.sfxVolume = sfxVolume;
        FlxG.save.flush();
    }

    static function load():Void {
        if (FlxG.save.data.musicVolume != null) {
            musicVolume = FlxG.save.data.musicVolume;
        }
        if (FlxG.save.data.sfxVolume != null) {
            sfxVolume = FlxG.save.data.sfxVolume;
        }
    }
}
