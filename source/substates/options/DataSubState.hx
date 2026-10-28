package substates.options;

import states.options.BaseOptionsMenu;

class DataSubState extends BaseOptionsMenu
{
    public function new() super("Data");

    override public function buildRows():Void
    {
        // Save Data
        // Load Data
        // Delete Data

        addString("Account", "signInAction", ["Sign In / Manage"], "Manage your AliA Online account");
        
        addBool("Check Updates", "checkForUpdates", "Check for game updates.");
        #if android
        addString("Storage Type", "storageType", ["EXTERNAL_DATA"], "Storage location used by the Android build.");
        #end
    }
}
