package states.online.mods;

#if sys
import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import states.online.mods.ModInstaller.ModMeta;

using StringTools;

class ModLoader {
	public static var loadedMods:Array<ModMeta> = [];
	public static var disabledMods:Array<String> = [];

	public static function loadAllMods():Void
	{
		loadedMods = [];
		var modsDir = getModsDirectory();
	  
		if (!FileSystem.exists(modsDir)) return;
	  
		for (item in FileSystem.readDirectory(modsDir))
		{
			var fullPath = modsDir + "/" + item;
			
			if (FileSystem.isDirectory(fullPath) && !item.startsWith(".") && !isModDisabled(item))
			{
				var meta = ModInstaller.readMeta(item);
				if (meta != null)
				{
					loadedMods.push(meta);
				}
			}
		}
	}

	public static function enable(mod:String):Void
	{
		if (disabledMods.contains(mod)) {
			disabledMods.remove(mod);
		}
		loadAllMods();
	}

	public static function disable(mod:String):Void
	{
		if (!disabledMods.contains(mod)) {
			disabledMods.push(mod);
		}
		loadAllMods();
	}

	public static function isModEnabled(mod:String):Bool
	{
		return !disabledMods.contains(mod);
	}

	public static function isModDisabled(mod:String):Bool
	{
		return disabledMods.contains(mod);
	}

	public static function loadZipMods():Void
	{
		var modsDir = getModsDirectory();
		if (!FileSystem.exists(modsDir)) return;

		for (item in FileSystem.readDirectory(modsDir))
		{
			var fullPath = modsDir + "/" + item;
			if (!FileSystem.isDirectory(fullPath) && item.toLowerCase().endsWith(".zip"))
			{
				var result = ModInstaller.install(fullPath, true);
				switch (result) {
					case Success(meta):
						trace("Successfully auto-installed ZIP mod: " + meta.name);
					case AlreadyInstalled(meta):
						trace("ZIP mod already installed: " + meta.name);
					case InvalidZip(reason):
						trace("Invalid ZIP found: " + reason);
					case MissingMeta:
						trace("ZIP mod skipped (Missing mod.json): " + item);
					case Failed(reason):
						trace("Failed to install ZIP mod: " + reason);
				}
			}
		}
	}

	public static function getLoadedMods():Array<ModMeta>
	{
		return loadedMods;
	}

	static function getModsDirectory():String
	{
		return #if mobile StorageUtil.getStorageDirectory() + #end "mods";
	}
}
#end
