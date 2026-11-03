package data.backend;

import bin.BIN;
import bin.BINValue;
import bin.BINObject;
import openfl.utils.Assets;

#if sys
import sys.FileSystem;
#end

/**
 * Loads the binary stage/act configuration.
 *
 * Stage files are stored at:
 *   assets/levels/<StageName>/Act<act>.bin
 *
 * This class owns stage directory selection and Act*.bin parsing.
 * LevelBin is the separate Level.bin format used by the level editor.
 */
class StageData
{
	public static var forceNextDirectory:String = null;
	public static var currentAct:Int = 1;

	public static function loadDirectory(stageName:String, act:Int = 1):Void
	{
		currentAct = act;
		var stageData:BINValue = getStageFile(stageName, act);

		if (stageData == null || !stageData.isObject())
		{
			forceNextDirectory = "";
			return;
		}

		var stageObject:BINObject = stageData.asObject();
		var directoryValue:BINValue = stageObject.get("directory");
		if (directoryValue != null)
		{
			var directory = directoryValue.asString("");
			if (directory != null && directory.length > 0)
			{
				forceNextDirectory = directory;
				return;
			}
		}

		forceNextDirectory = (stageName + act).toLowerCase();
	}

	public static function getLevelAssetPath(stageName:String, act:Int, fileName:String):String
	{
		var relative = "levels/" + stageName + "/" + fileName;
		#if MODS_ALLOWED
		var modPath = Paths.modFolders(relative);
		#if sys
		if (FileSystem.exists(modPath)) return modPath;
		#end
		#end
		return Paths.getSharedPath(relative);
	}

	public static function getStageFile(stageName:String, act:Int):BINValue
	{
		var relative = "levels/" + stageName + "/Act" + act + ".bin";
		var path = Paths.getSharedPath(relative);

		try
		{
			#if sys
			#if MODS_ALLOWED
			var modPath = Paths.modFolders(relative);
			if (FileSystem.exists(modPath)) return BIN.read(modPath);
			#end
			if (FileSystem.exists(path)) return BIN.read(path);
			#else
			if (Assets.exists(path))
			{
				var bytes = Assets.getBytes(path);
				if (bytes != null) return BIN.parse(bytes);
			}
			#end
		}
		catch (e:Dynamic)
		{
			trace("[StageData] Failed to load " + relative + ": " + Std.string(e));
		}
		return null;
	}
}
