package states.menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup;
import haxe.Json;
import StringTools;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import lime.ui.FileDialog;
import lime.ui.FileDialogType;

import states.MenuState;
import states.online.mods.ModLoader;
import states.online.mods.ModInstaller;

class ModsState extends GameState
{
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

        var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/background'));
        add(bg);

        var titleText = new FlxText(0, 20, 0, "MOD MANAGER", 24);
        titleText.screenCenter(FlxAxes.X);
        add(titleText);

        reloadModList();

		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.music('menus/menu'));

        #if mobile
        addCustomDPad('NONE', 'BACK');
        addCustomDPadCam();
        #end
    }

    function reloadModList():Void
    {
        var modsDir = #if mobile StorageUtil.getStorageDirectory() + #end "mods";
        #if sys
        if (!FileSystem.exists(modsDir)) FileSystem.createDirectory(modsDir);
        #end

        var cardWidth:Int = Std.int(Math.min(720, FlxG.width - 36));
        var cardX:Float = (FlxG.width - cardWidth) * 0.5;
        var yPos:Float = 76;
        var foundMods:Bool = false;

        #if sys
        for (item in FileSystem.readDirectory(modsDir))
        {
            var fullPath = modsDir + "/" + item;
            if (!FileSystem.isDirectory(fullPath) || StringTools.startsWith(item, ".")) continue;

            var metaPath = fullPath + "/mod.json";
            if (!FileSystem.exists(metaPath)) continue;

            var rawMeta:Dynamic = null;
            try rawMeta = tjson.TJSON.parse(File.getContent(metaPath)) catch (e:Dynamic)
            {
                trace('[ModsState] Invalid mod.json in ' + item + ': ' + Std.string(e));
                continue;
            }

            var meta:Dynamic = Reflect.hasField(rawMeta, "metaData") ? Reflect.field(rawMeta, "metaData") : rawMeta;
            if (meta == null) continue;

            var modName = readString(meta, "name", item);
            var author = readString(meta, "author", "Unknown author");
            var description = readString(meta, "description", "");
            var version = readString(meta, "modVersion", readString(meta, "version", "1.0.0"));
            var website = readString(meta, "URL", readString(meta, "url", ""));

            var settings:Array<Dynamic> = [];
            var settingsPath = fullPath + "/settings.json";
            if (FileSystem.exists(settingsPath))
            {
                try
                {
                    var settingsRoot:Dynamic = tjson.TJSON.parse(File.getContent(settingsPath));
                    var rawSettings:Dynamic = Reflect.field(settingsRoot, "setTings");
                    if (Std.isOfType(rawSettings, Array)) settings = cast rawSettings;
                    else if (rawSettings != null) trace('[ModsState] setTings must be an array in ' + item + '/settings.json');
                }
                catch (e:Dynamic) trace('[ModsState] Invalid settings.json in ' + item + ': ' + Std.string(e));
            }

            foundMods = true;
            var card = new FlxSprite(cardX, yPos);
            card.makeGraphic(cardWidth, 100, 0xFF202630);
            add(card);

            var iconPath = fullPath + "/mod.png";
            var icon = new FlxSprite(cardX + 12, yPos + 12);
            if (FileSystem.exists(iconPath))
            {
                try
                {
                    var bitmap = openfl.display.BitmapData.fromFile(iconPath);
                    if (bitmap != null) icon.loadGraphic(bitmap);
                    else icon.makeGraphic(72, 72, 0xFF555555);
                }
                catch (e:Dynamic) icon.makeGraphic(72, 72, 0xFF555555);
            }
            else icon.makeGraphic(72, 72, 0xFF555555);
            icon.setGraphicSize(72, 72);
            icon.updateHitbox();
            add(icon);

            var textX = cardX + 98;
            var textWidth = cardWidth - 112;
            var title = new FlxText(textX, yPos + 10, textWidth, modName, 17);
            title.setFormat(null, 17, FlxColor.WHITE, LEFT);
            add(title);

            var detailsText = author + "  |  v" + version;
            if (description.length > 0) detailsText += "  |  " + description;
            if (settings.length > 0) detailsText += "  |  " + settings.length + " settings";
            if (website.length > 0) detailsText += "  |  " + website;
            var details = new FlxText(textX, yPos + 36, textWidth, detailsText, 10);
            details.setFormat(null, 10, FlxColor.LIGHT_GRAY, LEFT);
            add(details);

            var enabled = ModLoader.isModEnabled(item);
            var enableBtn = new FlxButton(textX, yPos + 66, enabled ? "Disable" : "Enable", function() {
                if (enabled) ModLoader.disable(item);
                else ModLoader.enable(item);
                FlxG.resetState();
            });
            add(enableBtn);
            yPos += 112;
        }
        #end

        if (!foundMods)
        {
            var empty = new FlxText(cardX, yPos + 24, cardWidth, "No mods found. Add a mod folder with mod.json and mod.png.", 13);
            empty.setFormat(null, 13, FlxColor.WHITE, CENTER);
            add(empty);
            yPos += 70;
        }

        var installBtn = new FlxButton(0, yPos + 16, "Load ZIP Mod", function() {
            var fileDialog = new FileDialog();
            fileDialog.onSelect.add(function(path:String) {
                var result = ModInstaller.install(path, true);
                switch (result) {
                    case Success(meta): trace("Successfully installed mod: " + meta.name);
                    case AlreadyInstalled(meta): trace("Mod already installed: " + meta.name);
                    case InvalidZip(reason): trace("Invalid ZIP: " + reason);
                    case MissingMeta: trace("Missing or invalid mod.json.");
                    case Failed(reason): trace("Installation failed: " + reason);
                }
                FlxG.resetState();
            });
            fileDialog.open("zip", null, "Select Mod ZIP");
        });
        installBtn.screenCenter(FlxAxes.X);
        add(installBtn);

        var reloadBtn = new FlxButton(0, yPos + 52, "Reload Mods", function() {
            ModLoader.loadAllMods();
            FlxG.resetState();
        });
        reloadBtn.screenCenter(FlxAxes.X);
        add(reloadBtn);
    }

    static function readString(source:Dynamic, field:String, fallback:String):String
    {
        if (source != null && Reflect.hasField(source, field))
        {
            var value = Reflect.field(source, field);
            if (value != null && Std.string(value).length > 0) return Std.string(value);
        }
        return fallback;
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.music('menus/menu'));

        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancel_sound'));
            GameState.switchState(new MenuState());
        }
    }
}

class ModPack extends FlxSpriteGroup
{
	public var folder:String = 'unknownMod';
	public var icon:FlxSprite;
	public var text:FlxText;
	public var name:String = 'Unknown Mod';
	public var author:String = 'Unknown User';
	public var desc:String = 'No description provided.';
	public var pack:Dynamic = null;
	public var mustRestart:Bool = false;
	public var settings:Array<Dynamic> = null;

	public function new(folder:String)
	{
		super();
	}
}
