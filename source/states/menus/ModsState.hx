package states.menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxAxes;
import sys.FileSystem;
import sys.io.File;
import lime.ui.FileDialog;
import lime.ui.FileDialogType;
import haxe.io.Bytes;

import states.MenuState;
import states.online.mods.ModLoader;

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
                var txt = new FlxText(0, yPos, FlxG.width, item, 16);
                txt.alignment = CENTER;
                add(txt);

                var isEnabled = ModLoader.isModEnabled(item);
                var enableBtn = new FlxButton(0, yPos + 22, isEnabled ? "Disable" : "Enable", function() {
                    if (isEnabled) {
                        ModLoader.disable(item);
                    } else {
                        ModLoader.enable(item);
                    }
                    FlxG.resetState();
                });
                enableBtn.screenCenter(FlxAxes.X);
                add(enableBtn);
                yPos += 70;
            }
        }

        var installBtn = new FlxButton(0, yPos + 20, "Load ZIP Mod", function() {
            var fileDialog = new FileDialog();
            
            fileDialog.onSelect.add(function(path:String) {
                unzipMod(path, modsDir);
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

    function unzipMod(zipPath:String, destination:String) {
        try {
            var input = File.read(zipPath, true);
            var entries = format.zip.Reader.readAll(input);
            input.close();

            for (entry in entries) {
                var fileName = entry.fileName;
                var targetPath = destination + "/" + fileName;

                if (StringTools.endsWith(fileName, "/") || StringTools.endsWith(fileName, "\\")) {
                    FileSystem.createDirectory(targetPath);
                } else {
                    var dir = haxe.io.Path.directory(targetPath);
                    if (!FileSystem.exists(dir)) {
                        FileSystem.createDirectory(dir);
                    }
                    var uncompressedData = format.zip.Tools.unzip(entry);
                    File.saveBytes(targetPath, uncompressedData);
                }
            }
            
            trace("Successfully extracted zip mod!");
            FlxG.resetState();
        } catch (e:Dynamic) {
            trace("Failed to extract zip: " + e);
        }
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancel_sound'));
        }
    }
}
