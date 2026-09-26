package data.backend;

import openfl.utils.Assets;
import ellawy.bin.BIN;
import ellawy.bin.BINValue;
import ellawy.bin.BINObject;

#if sys
import sys.FileSystem;
#end

class StageData {
	public static var forceNextDirectory:String = null;

	public static function loadDirectory(stageName:String) {
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

		var stageData:BINValue = getStageFile(stageName);

		if (stageData == null) {
			forceNextDirectory = '';
		} else {
			if (stageData.isObject()) {
				var obj:BINObject = stageData.asObject();
				
				if (obj.exists("directory")) {
					forceNextDirectory = obj.get("directory").asString();
				} else {
					forceNextDirectory = stageName.toLowerCase();
				}
			} else {
				forceNextDirectory = stageName.toLowerCase();
			}
		}
	}

	public static function getStageFile(stage:String):BINValue {
		var path:String = Paths.getLevelPath('levels/' + stage + '/' + stage + '.bin');
		var parsedData:BINValue = null;

		#if MODS_ALLOWED
		var modPath:String = Paths.modFolders('levels/' + stage + '/' + stage + '.bin');
		if (FileSystem.exists(modPath)) {
			parsedData = BIN.read(modPath);
		} else if (FileSystem.exists(path)) {
			parsedData = BIN.read(path);
		}
		#else
		if (Assets.exists(path)) {
			var bytes = Assets.getBytes(path);
			if (bytes != null) {
				parsedData = BIN.parse(bytes);
			}
		}
		#end

		return parsedData;
	}
}
