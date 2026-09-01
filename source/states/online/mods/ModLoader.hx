package states.online.mods;

#if sys
import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import online.mods.ModInstaller.ModMeta;
import haxe.zip.Reader;

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
			if (!FileSystem.isDirectory(fullPath) && StringTools.endsWith(item.toLowerCase(), ".zip"))
			{
				var folderName = item.substr(0, item.length - 4);
				var targetDir = modsDir + "/" + folderName;
				
				if (!FileSystem.exists(targetDir)) {
					FileSystem.createDirectory(targetDir);

					try {
						var input = File.read(fullPath, true);
						var reader = new Reader(input);
						var entries = reader.read();
						input.close();

						for (entry in entries)
						{
							var fileName = entry.fileName;
							var destPath = targetDir + "/" + fileName;

							if (StringTools.endsWith(fileName, "/") || StringTools.endsWith(fileName, "\\"))
							{
								FileSystem.createDirectory(destPath);
							}
							else
							{
								var dir = haxe.io.Path.directory(destPath);
								if (!FileSystem.exists(dir))
								{
									FileSystem.createDirectory(dir);
								}
								var uncompressedData = Reader.unzip(entry);
								File.saveBytes(destPath, uncompressedData);
							}
						}
					} catch (e:Dynamic) {
						trace("Failed to extract ZIP mod: " + item + " - " + e);
					}
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
