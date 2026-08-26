package data;

import openfl.utils.Assets;
// import haxe.Json;

class StageData {
	public static var forceNextDirectory:String = null;

	public static function loadDirectory() {
		var stage:String = [
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

		var stageFile:StageFile = getStageFile(stage);
		if(stageFile == null) { //preventing crashes
			forceNextDirectory = '';
		} else {
			forceNextDirectory = stageFile.directory;
		}
	}

	public static function getStageFile(stage:String) {
		var raw:String = null;
		var path:String = Paths.getLevelPath('levels/' + stage + '/' + stage + '.bin');

		#if MODS_ALLOWED
		var modPath:String = Paths.modFolders('levels/' + stage + '/' + stage + '.bin');
		if(FileSystem.exists(modPath)) {
			raw = File.getContent(modPath);
		} else if(FileSystem.exists(path)) {
			raw = File.getContent(path);
		}
		#else
		if(Assets.exists(path)) {
			raw = Assets.getText(path);
		}
		#end
		else
		{
			return null;
		}
		// return cast ellawy.BIN.parse(raw);
	}
}
