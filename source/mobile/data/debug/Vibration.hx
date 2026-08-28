package mobile.data.debug;

#if android
import lime.system.JNI;
#end

import flixel.FlxG;

enum VibrationPattern {
    Short;
    Medium;
    Long;
    DoublePulse;
    Custom(durationMs:Int);
}

class Vibration {

    public static var enabled(default, set):Bool = true;

    static inline var MIN_INTERVAL_MS:Int = 80;
    static var lastTriggerTime:Float = 0;

    #if android
    static var vibrateFn:Dynamic;
    static var cancelFn:Dynamic;
    static var hasVibrator:Bool = false;
    static var initialized:Bool = false;
    #end

    public static function init():Void {
        load();

        #if android
        setupJNI();
        #end
    }

    public static function trigger(pattern:VibrationPattern):Void {
        if (!enabled) return;
        if (!canTriggerNow()) return;

        var durationMs = patternToDuration(pattern);

        #if android
        doVibrate(durationMs);
        #end

        lastTriggerTime = getTimeMs();
    }

    public static function cancel():Void {
        #if android
        if (hasVibrator && cancelFn != null) {
            try {
                cancelFn();
            } catch (e:Dynamic) {}
        }
        #end
    }

    #if android
    static function setupJNI():Void {
        if (initialized) return;
        initialized = true;

        try {
            vibrateFn = JNI.createStaticMethod(
                "org/haxe/lime/HaxeObject",
                "vibrate",
                "(J)V"
            );
        } catch (e:Dynamic) {
            hasVibrator = false;
            return;
        }

        hasVibrator = true;
    }

    static function doVibrate(durationMs:Int):Void {
        if (!hasVibrator) return;

        try {
            var context = JNI.createStaticField("org/haxe/lime/HaxeObject", "mainActivity", "Landroid/app/Activity;").get();
            var vibratorService = JNI.createStaticMethod(
                "android/content/Context",
                "getSystemService",
                "(Ljava/lang/String;)Ljava/lang/Object;"
            );

            var vibrator = vibratorService(context, "vibrator");
            if (vibrator == null) return;

            var vibrateMethod = JNI.createMemberMethod(
                "android/os/Vibrator",
                "vibrate",
                "(J)V"
            );

            vibrateMethod(vibrator, durationMs);
        } catch (e:Dynamic) {}
    }
    #end

    static function patternToDuration(pattern:VibrationPattern):Int {
        return switch (pattern) {
            case Short: 40;
            case Medium: 100;
            case Long: 250;
            case DoublePulse: 60;
            case Custom(durationMs): durationMs;
        }
    }

    static function canTriggerNow():Bool {
        return getTimeMs() - lastTriggerTime >= MIN_INTERVAL_MS;
    }

    static function getTimeMs():Float {
        return Date.now().getTime();
    }

    static function set_enabled(value:Bool):Bool {
        enabled = value;
        save();
        return enabled;
    }

    static function save():Void {
        FlxG.save.data.vibrationEnabled = enabled;
        FlxG.save.flush();
    }

    static function load():Void {
        if (FlxG.save.data.vibrationEnabled != null) {
            enabled = FlxG.save.data.vibrationEnabled;
        }
    }
}
