package states.menus;

import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import sys.FileSystem;
import sys.io.File;
// import modding.ZipInstaller;
// import modding.ModLoader;

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

        add(new FlxText(20, 20, 0, "MOD MANAGER", 24));

        var yPos = 80;

        if (FileSystem.exists(#if mobile StorageUtil.getStorageDirectory() + #end "mods")) {
            for (mod in FileSystem.readDirectory(#if mobile StorageUtil.getStorageDirectory() + #end "mods")) {
                var txt = new FlxText(20, yPos, 0, mod, 16);
                add(txt);

                var enableBtn = new FlxButton(200, yPos, "Enable", function() {
                    //ModLoader.enable(mod);
                });

                var disableBtn = new FlxButton(280, yPos, "Disable", function() {
                    //ModLoader.disable(mod);
                });

                add(enableBtn);
                add(disableBtn);

                yPos += 40;
            }
        }

        var installBtn = new FlxButton(20, yPos + 40, "Install ZIP Mods", function() {
            // installAllZips();
        });
        add(installBtn);

        var reloadBtn = new FlxButton(20, yPos + 90, "Reload Mods", function() {
            // ModLoader.loadAllMods();
        });
        add(reloadBtn);

		#if mobile
		addCustomDPad('NONE', 'BACK');
		addCustomDPadCam();
		#end
    }

    /*function installAllZips() {
        var storageFile = StorageUtil.StorageType;
        var zipDir = "/storage/emulated/0/" + storageFile + "/mods/";
        if (!FileSystem.exists(zipDir)) return;

        for (zip in FileSystem.readDirectory(zipDir)) {
            ZipInstaller.install(zipDir + zip);
        }
    }*/

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (controls.BACK) {
            GameState.switchState(new MenuState());
        }
    }
}
