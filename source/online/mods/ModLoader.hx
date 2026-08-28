package online.mods;

#if sys
import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import online.mods.ModInstaller.ModMeta;

class ModLoader {
	public static var loadedMods:Array<ModMeta> = [];

	public static function loadAllMods():Void
	{
	      loadedMods = [];
	      var modsDir = getModsDirectory();
	  
	      if (!FileSystem.exists(modsDir)) return;
	  
	      for (item in FileSystem.readDirectory(modsDir))
	      {
	          var fullPath = modsDir + "/" + item;
	          
	          if (FileSystem.isDirectory(fullPath) && !item.startsWith("."))
	          {
	              var meta = ModInstaller.readMeta(item);
	              if (meta != null)
	              {
	                  loadedMods.push(meta);
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
