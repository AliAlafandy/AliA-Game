package substates.options;

import states.options.BaseOptionsMenu;

class DataSubState extends BaseOptionsMenu
{
    public function new() super("Data");

    override public function buildRows():Void
    {
        // Sign In
        // Save Data
        // Load Data
        // Delete Data
        addBool("Check Updates", "checkForUpdates", "Check for game updates.");

        #if android
        addString("Storage Type", "storageType", ["EXTERNAL_DATA"], "Storage location used by the Android build.");
        #end
    }
}
