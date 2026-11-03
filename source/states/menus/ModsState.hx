package states.menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup;
import haxe.Json;
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

        if (!FileSystem.exists(modsDir)) {
            FileSystem.createDirectory(modsDir);
        }

        var yPos = 80;
        for (item in FileSystem.readDirectory(modsDir)) {
            var fullPath = modsDir + "/" + item;
            
            if (FileSystem.isDirectory(fullPath)) {
                // Read each mod's own metadata instead of displaying only its folder name.
                var meta:Dynamic = null;
                var metaPath = fullPath + "/mod.json";
                if (FileSystem.exists(metaPath)) {
                    try meta = Json.parse(File.getContent(metaPath)) catch (e:Dynamic) {
                        trace('[ModsState] Invalid mod.json in ' + item + ': ' + Std.string(e));
                    }
                }

                if (meta == null) {
                    trace('[ModsState] Skipping folder without a valid mod.json: ' + item);
                    continue;
                }

                var modName:String = Reflect.hasField(meta, "name") && meta.name != null ? Std.string(meta.name) : item;
                var author:String = Reflect.hasField(meta, "author") && meta.author != null ? Std.string(meta.author) : "Unknown author";
                var description:String = Reflect.hasField(meta, "description") && meta.description != null ? Std.string(meta.description) : "";

                // mod.png is the standard folder icon. Keep a generated placeholder
                // when an optional icon is missing so the list remains usable.
                var iconPath = fullPath + "/mod.png";
                var icon = new FlxSprite(24, yPos);
                if (FileSystem.exists(iconPath)) {
                    try {
                        var bitmap = openfl.display.BitmapData.fromFile(iconPath);
                        if (bitmap != null) icon.loadGraphic(bitmap);
                        else icon.makeGraphic(56, 56, 0xFF30445B);
                    } catch (e:Dynamic) {
                        icon.makeGraphic(56, 56, 0xFF30445B);
                    }
                } else {
                    icon.makeGraphic(56, 56, 0xFF30445B);
                }
                icon.setGraphicSize(56, 56);
                icon.updateHitbox();
                add(icon);

                var title = new FlxText(92, yPos, FlxG.width - 110, modName, 16);
                title.setFormat(null, 16, FlxColor.WHITE, LEFT);
                add(title);

                var details = new FlxText(92, yPos + 22, FlxG.width - 110,
                    author + (description.length > 0 ? " - " + description : ""), 11);
                details.setFormat(null, 11, FlxColor.GRAY, LEFT);
                add(details);

                var isEnabled = ModLoader.isModEnabled(item);
                var enableBtn = new FlxButton(92, yPos + 43, isEnabled ? "Disable" : "Enable", function() {
                    if (isEnabled) ModLoader.disable(item);
                    else ModLoader.enable(item);
                    FlxG.resetState();
                });
                add(enableBtn);
                yPos += 112;
            }
        }

        var installBtn = new FlxButton(0, yPos + 20, "Load ZIP Mod", function() {
            var fileDialog = new FileDialog();
            
            fileDialog.onSelect.add(function(path:String) {
                var result = ModInstaller.install(path, true);
                switch (result) {
                    case Success(meta):
                        trace("Successfully installed mod: " + meta.name);
                    case AlreadyInstalled(meta):
                        trace("Mod already installed: " + meta.name);
                    case InvalidZip(reason):
                        trace("Invalid ZIP: " + reason);
                    case MissingMeta:
                        trace("Error: Missing or invalid mod.json inside ZIP root or folder structure.");
                    case Failed(reason):
                        trace("Installation failed: " + reason);
                }
                FlxG.resetState();
            });
            
            fileDialog.open("zip", null, "Select Mod ZIP");
        });
        installBtn.screenCenter(FlxAxes.X);
        add(installBtn);

        var reloadBtn = new FlxButton(0, yPos + 55, "Reload Mods", function() {
            ModLoader.loadAllMods();
            FlxG.resetState();
        });
        reloadBtn.screenCenter(FlxAxes.X);
        add(reloadBtn);
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
