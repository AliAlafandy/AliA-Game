package states.menus;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxAxes;
import sys.FileSystem;
import sys.io.File;

import states.MenuState;

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

        var yPos = 80;

        if (FileSystem.exists(#if mobile StorageUtil.getStorageDirectory() + #end "mods")) {
            for (mod in FileSystem.readDirectory(#if mobile StorageUtil.getStorageDirectory() + #end "mods")) {
                var txt = new FlxText(0, yPos, FlxG.width, mod, 16);
                txt.alignment = CENTER;
                add(txt);

                var enableBtn = new FlxButton(FlxG.width / 2 - 90, yPos + 22, "Enable", function() {
                    //ModLoader.enable(mod);
                });

                var disableBtn = new FlxButton(FlxG.width / 2 + 10, yPos + 22, "Disable", function() {
                    //ModLoader.disable(mod);
                });

                add(enableBtn);
                add(disableBtn);

                yPos += 70;
            }
        }

        /*var installBtn = new FlxButton(0, yPos + 20, "Install ZIP Mods", function() {
        // installAllZips();
        });
        installBtn.screenCenter(FlxAxes.X);
        add(installBtn);*/

        var reloadBtn = new FlxButton(0, yPos + 20, "Reload Mods", function() { // 60
        // ModLoader.loadAllMods();
        });
        reloadBtn.screenCenter(FlxAxes.X);
        add(reloadBtn);

        #if mobile
        addCustomDPad('NONE', 'BACK');
        addCustomDPadCam();
        #end
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (controls.BACK) {
            GameState.switchState(new MenuState());
        }
    }
}
