package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;

import online.Network;

class OnlineState extends GameState {

    static inline var ENTRY_HEIGHT:Int = 60;
    static inline var LIST_START_Y:Int = 80;

    var mods:Array<Dynamic> = [];
    var listGroup:FlxTypedGroup<FlxSprite>;
    var statusText:FlxText;

    var scrollY:Float = 0;
    var maxScroll:Float = 0;

    #if mobile
    public var manager:MobileInputManager;
    var lastTouchY:Float = 0;
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

        statusText = new FlxText(20, 60, 0, "Loading mods...", 16);
        add(statusText);

        listGroup = new FlxTypedGroup<FlxSprite>();
        add(listGroup);

        loadModList();

        #if mobile
        addCustomDPad();
        addCustomDPadCam();
        #end
    }

    function loadModList():Void {
        Network.fetchJson("https://alialafandy.github.io/AliA-Online/mods.json", onModsLoaded, onModsFailed);
    }

    function onModsLoaded(data:Dynamic):Void {
        mods = data;
        statusText.text = mods.length == 0 ? "No mods available" : "";
        renderList();
    }

    function onModsFailed(reason:String):Void {
        statusText.text = "Failed to load mods list";
    }

    function renderList():Void {
        listGroup.clear();

        var y = LIST_START_Y;
        for (mod in mods) {
            var nameText = new FlxText(20, y, 300, mod.name + " - " + mod.author, 16);
            listGroup.add(nameText);

            var descText = new FlxText(20, y + 18, 300, mod.description, 12);
            listGroup.add(descText);

            var btn = new FlxButton(400, y, "Download", null);
            btn.onUp.callback = function() downloadMod(mod.zip, btn);
            listGroup.add(btn);

            y += ENTRY_HEIGHT;
        }

        maxScroll = Math.max(0, y - FlxG.height + 140);
        scrollY = 0;
        listGroup.y = 0;
    }

    function downloadMod(url:String, btn:FlxButton):Void {
        #if sys
        btn.onUp.callback = null;
        btn.text = "0%";

        var dir = getModsDirectory();
        var fileName = url.split("/").pop();
        var savePath = dir + "/" + fileName;

        Network.downloadFile(url, savePath,
            function(loaded, total) {
                btn.text = total > 0 ? Std.int(loaded / total * 100) + "%" : "...";
            },
            function(path) {
                try {
                    ZipInstaller.install(path);
                    ModLoader.loadAllMods();
                    btn.text = "Installed";
                } catch (e:Dynamic) {
                    btn.text = "Install failed";
                }
            },
            function(reason) {
                btn.text = "Failed";
            }
        );
        #else
        btn.text = "Unsupported";
        #end
    }

    #if sys
    function getModsDirectory():String {
        return #if mobile StorageUtil.getStorageDirectory() + #end "mods";
    }
    #end

    override public function update(elapsed:Float) {
        super.update(elapsed);

        #if mobile
        handleScrollInput();
        #else
        if (FlxG.mouse.wheel != 0) {
            scrollY = clampScroll(scrollY - FlxG.mouse.wheel * 20);
            listGroup.y = -scrollY;
        }
        #end

        if (controls.BACK) {
            FlxG.switchState(new MenuState());
        }
    }

    #if mobile
    function handleScrollInput():Void {
        var touch = FlxG.touches.getFirst();
        if (touch == null) return;

        if (touch.justPressed) {
            lastTouchY = touch.screenY;
        } else if (touch.pressed) {
            var delta = lastTouchY - touch.screenY;
            scrollY = clampScroll(scrollY + delta);
            listGroup.y = -scrollY;
            lastTouchY = touch.screenY;
        }
    }
    #end

    function clampScroll(value:Float):Float {
        return Math.max(0, Math.min(maxScroll, value));
    }
}
