package states;

import flixel.text.FlxText;
import flixel.ui.FlxButton;
import haxe.Http;
import haxe.Json;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

// import modding.ZipInstaller;
// import modding.ModLoader;

class OnlineState extends GameState {
    var mods:Array<Dynamic> = [];

    #if mobile
    public var manager:MobileInputManager;
    #end

    public function new():Void
    {
        super();
        #if mobile
        manager = new MobileInputManager();
        #end
    }

    override public function create() {
        super.create();
        add(new FlxText(20, 20, 0, "ONLINE MODS", 24));

        loadModList();
    }

    function loadModList() {
        var url = "https://alialafandy.github.com/AliA-Online/";

        var http = new Http(url);
        http.onData = function(data:String) {
            mods = Json.parse(data);
            renderList();
        };
        http.onError = function(e) {
            add(new FlxText(20, 60, 0, "Failed to load mods list", 16));
        };
        http.request();
    }

    function renderList() {
        var y = 80;

        for (mod in mods) {
            add(new FlxText(20, y, 0, mod.name + " - " + mod.author, 16));
            add(new FlxText(20, y + 18, 0, mod.description, 12));

            var btn = new FlxButton(400, y, "Download", function() {
                downloadMod(mod.zip);
            });
            add(btn);

            y += 60;
        }
    }

    function downloadMod(url:String) {
    	var storageFile = StorageUtil.StorageType;
        var zipDir = "/storage/emulated/0/" + storageFile + "/mods/";
        if (!FileSystem.exists(zipDir)) FileSystem.createDirectory(zipDir);

        var fileName = url.split("/").pop();
        var savePath = zipDir + fileName;

        var http = new Http(url);
        http.onBytes = function(bytes) {
            File.saveBytes(savePath, bytes);
            ZipInstaller.install(savePath);
            ModLoader.loadAllMods();
        };
        http.onError = function(e) {
            trace("Download failed: " + e);
        };
        http.request();
    }
}
