package substates.options;

import states.options.BaseOptionsMenu;

class DataSubState extends BaseOptionsMenu
{
    public function new() super("Data");

    override public function buildRows():Void
    {
                addBool("Check for updates", "checkForUpdates", "Check for game updates.");
                addBool("Loading screen", "loadingScreen", "Show the loading screen.");
                addBool("Screensaver", "screensaver", "Enable the screensaver.");
                addBool("Auto pause", "autoPause", "Pause when the app loses focus.");
                #if android
                addString("Storage type", "storageType", ["EXTERNAL_DATA"], "Storage location used by the Android build.");
                #end
    }
}
