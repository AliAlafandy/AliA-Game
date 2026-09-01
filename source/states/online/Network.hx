package states.online;

import haxe.Json;
import haxe.Timer;

import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Network {

    static inline var DEFAULT_TIMEOUT:Float = 15.0;
    static inline var DEFAULT_RETRIES:Int = 2;

    public static function fetchJson(url:String, onSuccess:Dynamic->Void, onError:String->Void,
            retries:Int = DEFAULT_RETRIES):Void {
        var loader = new URLLoader();
        loader.dataFormat = URLLoaderDataFormat.TEXT;

        var timedOut = false;
        var timeoutTimer = Timer.delay(function() {
            timedOut = true;
            try loader.close() catch (e:Dynamic) {}
            handleFailure(url, "Request timed out", onSuccess, onError, retries, fetchJson);
        }, Std.int(DEFAULT_TIMEOUT * 1000));

        loader.addEventListener(Event.COMPLETE, function(e) {
            if (timedOut) return;
            timeoutTimer.stop();

            try {
                onSuccess(Json.parse(loader.data));
            } catch (err:Dynamic) {
                onError("Failed to parse response: " + Std.string(err));
            }
        });

        loader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent) {
            if (timedOut) return;
            timeoutTimer.stop();
            handleFailure(url, e.text, onSuccess, onError, retries, fetchJson);
        });

        try {
            loader.load(new URLRequest(url));
        } catch (e:Dynamic) {
            timeoutTimer.stop();
            onError("Failed to start request: " + Std.string(e));
        }
    }

    static function handleFailure(url:String, reason:String, onSuccess:Dynamic->Void, onError:String->Void,
            retriesLeft:Int, retryFn:String->(Dynamic->Void)->(String->Void)->Int->Void):Void {
        if (retriesLeft > 0) {
            Timer.delay(function() {
                retryFn(url, onSuccess, onError, retriesLeft - 1);
            }, 500);
        } else {
            onError(reason);
        }
    }

    #if sys
    public static function downloadFile(url:String, savePath:String, ?onProgress:(loaded:Int, total:Int)->Void,
            ?onComplete:String->Void, ?onError:String->Void):Void {
        var dir = haxe.io.Path.directory(savePath);
        if (dir != "" && !FileSystem.exists(dir)) {
            FileSystem.createDirectory(dir);
        }

        var loader = new URLLoader();
        loader.dataFormat = URLLoaderDataFormat.BINARY;

        if (onProgress != null) {
            loader.addEventListener(ProgressEvent.PROGRESS, function(e:ProgressEvent) {
                onProgress(Std.int(e.bytesLoaded), Std.int(e.bytesTotal));
            });
        }

        loader.addEventListener(Event.COMPLETE, function(e) {
            try {
                var bytes:haxe.io.Bytes = loader.data;
                File.saveBytes(savePath, bytes);
                if (onComplete != null) onComplete(savePath);
            } catch (err:Dynamic) {
                if (onError != null) onError("Failed to save file: " + Std.string(err));
            }
        });

        loader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent) {
            if (onError != null) onError("Download failed: " + e.text);
        });

        try {
            loader.load(new URLRequest(url));
        } catch (e:Dynamic) {
            if (onError != null) onError("Failed to start download: " + Std.string(e));
        }
    }
    #end

    public static function isReachable(onResult:Bool->Void, testUrl:String = "https://github.com"):Void {
        fetchJson(testUrl, function(_) onResult(true), function(_) onResult(false), 0);
    }
}
