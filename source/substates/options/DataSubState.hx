package substates.options;

import states.options.BaseOptionsMenu;

class DataSubState extends BaseOptionsMenu
{
    #if android
    var storageTypes:Array<String> = ["EXTERNAL_DATA", "EXTERNAL_OBB", "EXTERNAL_MEDIA", "EXTERNAL"];
	var externalPaths:Array<String> = StorageUtil.checkExternalPaths(true);
	final lastStorageType:String = ClientPrefs.data.storageType;
    #end

    public function new()
	{
		heading.text = "Data";
		super("Data");
	}

    override public function buildRows():Void
    {
        addDynamic(
			"Account",
			"signInAction",
			"Manage your Ali-A Online account."
		);

        // Save Data

        // Load Data

        // Delete Data

        addBool(
			"Check Updates",
			"checkForUpdates",
			"Check for game updates."
		);

        #if android
        addString(
			"Storage Type",
			"storageType",
			storageTypes,
			"Storage location used by the Android build."
		);
        #end
    }

    #if android
	function onStorageChange():Void
	{
		File.saveContent(lime.system.System.applicationStorageDirectory + 'storagetype.txt', ClientPrefs.data.storageType);

		var lastStoragePath:String = StorageType.fromStrForce(lastStorageType) + '/';

		try
		{
			if (ClientPrefs.data.storageType != "EXTERNAL")
				Sys.command('rm', ['-rf', lastStoragePath]);
		}
		catch (e:haxe.Exception)
			trace('Failed to remove last directory. (${e.message})');
	}
	#end

    override public function destroy()
	{
		super.destroy();
		#if android
		if (ClientPrefs.data.storageType != lastStorageType)
		{
			onStorageChange();
			CoolUtil.showPopUp('Storage Type has been changed and you needed restart the game!!\nPress OK to close the game.', 'Notice!');
			lime.system.System.exit(0);
		}
		#end
    }
}
