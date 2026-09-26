package data.backend;

import openfl.utils.Assets;
import bin.BIN;
import bin.BINValue;
import bin.BINObject;

#if sys
import sys.FileSystem;
#end

class StageData {
    public static var forceNextDirectory:String = null;
    public static var currentAct:Int = 1;

    public static function loadDirectory(stageName:String, act:Int = 1) {
        currentAct = act;
        
        var stageData:BINValue = getStageFile(stageName, act);

        if (stageData == null) {
            forceNextDirectory = '';
        } else {
            if (stageData.isObject()) {
                var obj:BINObject = stageData.asObject();
                
                if (obj.exists("directory")) {
                    forceNextDirectory = obj.get("directory").asString();
                } else {
                    forceNextDirectory = (stageName + act).toLowerCase();
                }
            } else {
                forceNextDirectory = (stageName + act).toLowerCase();
            }
        }
    }

	public static function getLevelAssetPath(stageName:String, act:Int, fileName:String):String {
        var folderPath:String = 'levels/' + stageName.toLowerCase() + '/';
        
        #if MODS_ALLOWED
        var modPath:String = Paths.modFolders(folderPath + fileName);
        if (sys.FileSystem.exists(modPath)) {
            return modPath;
        }
        #end
        
        return folderPath + fileName;
    }

    public static function getStageFile(stageName:String, act:Int):BINValue {
        var fileName:String = "act" + act;
        var path:String = Paths.getSharedPath('levels/' + stageName.toLowerCase() + '/' + fileName + '.bin');
        var parsedData:BINValue = null;

        #if MODS_ALLOWED
        var modPath:String = Paths.modFolders('levels/' + stageName.toLowerCase() + '/' + fileName + '.bin');
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
