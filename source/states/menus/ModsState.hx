package states.menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxAxes;
import sys.FileSystem;
import sys.io.File;

import states.MenuState;
import states.online.mods.ModLoader;

class ModsState extends GameState {

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

        if (FileSystem.exists(modsDir)) {
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

            var installBtn = new FlxButton(0, yPos + 20, "Load ZIP Mods", function() {
                ModLoader.loadZipMods();
                FlxG.resetState();
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
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancel_sound'));
            GameState.switchState(new MenuState());
        }
    }
}
