package online;

import haxe.Http;
import haxe.Json;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Network {

    public static function fetchJson(url:String, onSuccess:Dynamic->Void, onError:String->Void):Void {
        var http = new Http(url);

        http.onData = function(data:String) {
            try {
                onSuccess(Json.parse(data));
            } catch (e:Dynamic) {
                onError("Failed to parse response: " + Std.string(e));
            }
        };

        http.onError = function(e) {
            onError("Request failed: " + Std.string(e));
        };

        http.request();
    }

    #if sys
    public static function downloadFile(url:String, savePath:String, ?onProgress:(loaded:Int, total:Int)->Void,
            ?onComplete:String->Void, ?onError:String->Void):Void {
        var dir = haxe.io.Path.directory(savePath);
        if (dir != "" && !FileSystem.exists(dir)) {
            FileSystem.createDirectory(dir);
        }

        var http = new Http(url);

        #if !html5
        if (onProgress != null) {
            http.onStatus = function(status:Int) {};
        }
        #end

        http.onBytes = function(bytes:haxe.io.Bytes) {
            try {
                File.saveBytes(savePath, bytes);
                if (onComplete != null) onComplete(savePath);
            } catch (e:Dynamic) {
                if (onError != null) onError("Failed to save file: " + Std.string(e));
            }
        };

        http.onError = function(e) {
            if (onError != null) onError("Download failed: " + Std.string(e));
        };

        http.request();
    }
    #end

    public static function isReachable(onResult:Bool->Void, testUrl:String = "https://github.com"):Void {
        var http = new Http(testUrl);
        http.onData = function(_) onResult(true);
        http.onError = function(_) onResult(false);
        http.request();
    }
}
