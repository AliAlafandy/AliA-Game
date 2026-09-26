package data.backend;

import openfl.utils.Assets;
import openfl.utils.ByteArray;
#if sys
import sys.FileSystem;
import sys.io.File;
#endif

class StageData {
	public static var forceNextDirectory:String = null;

	public static function loadDirectory() {
		var stages:Array = [
			'ATown',
			'Neon',
			'Nature',
			'Wet',
			'Water',
			'Desert',
			'Mountain',
			'Fire',
			'Air',
			'Space',
			'Doom',
			'Flash',
			'Special'
		];
		
		var currentStageName:String = stages[0]; 

		var stageDataBytes:ByteArray = getStageFileBytes(currentStageName);
		
		if(stageDataBytes == null) {
			forceNextDirectory = '';
		} else {
			stageDataBytes.position = 0;
			forceNextDirectory = currentStageName.toLowerCase();
		}
	}

	public static function getStageFileBytes(stage:String):ByteArray {
		var path:String = Paths.getLevelPath('levels/' + stage + '/' + stage + '.bin');
		var bytes:ByteArray = null;

		#if MODS_ALLOWED
		var modPath:String = Paths.modFolders('levels/' + stage + '/' + stage + '.bin');
		if(FileSystem.exists(modPath)) {
			var rawBytes = File.getBytes(modPath);
			bytes = ByteArray.fromBytes(rawBytes);
		} else if(FileSystem.exists(path)) {
			var rawBytes = File.getBytes(path);
			bytes = ByteArray.fromBytes(rawBytes);
		}
		#else
		if(Assets.exists(path)) {
			bytes = Assets.getBytes(path);
		}
		#end

		return bytes;
	}
}
