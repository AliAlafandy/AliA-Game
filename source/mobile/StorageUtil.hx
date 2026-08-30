package mobile;

import lime.system.System as LimeSystem;
import haxe.io.Path;
import haxe.Json;
import haxe.Exception;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

enum abstract StorageResult(Int)
{
	var OK = 0;
	var FAILED_WRITE = 1;
	var FAILED_READ = 2;
	var NOT_FOUND = 3;
	var INVALID_DATA = 4;
	var PERMISSION_DENIED = 5;
}

class StorageUtil
{
	#if sys
	public static final rootDir:String = LimeSystem.applicationStorageDirectory;

	private static inline var SAVES_FOLDER:String = 'saves';
	private static inline var BACKUPS_FOLDER:String = 'backups';
	private static inline var MAX_BACKUPS:Int = 5;
	private static inline var STORAGE_TYPE_FILE:String = 'storagetype.txt';

	private static var cachedStorageDir:String = null;
	private static var cachedForceFlag:Bool = false;

	public static function getStorageDirectory(?force:Bool = false):String
	{
		if (cachedStorageDir != null && cachedForceFlag == force)
			return cachedStorageDir;

		var daPath:String = '';

		#if android
		if (!FileSystem.exists(rootDir + STORAGE_TYPE_FILE))
			File.saveContent(rootDir + STORAGE_TYPE_FILE, ClientPrefs.data.storageType);

		var curStorageType:String = File.getContent(rootDir + STORAGE_TYPE_FILE);
		daPath = force ? StorageType.fromStrForce(curStorageType) : StorageType.fromStr(curStorageType);
		daPath = Path.addTrailingSlash(daPath);
		#elseif ios
		daPath = LimeSystem.documentsDirectory;
		#else
		daPath = Sys.getCwd();
		#end

		cachedStorageDir = daPath;
		cachedForceFlag = force;
		return daPath;
	}

	public static function invalidateCache():Void
	{
		cachedStorageDir = null;
	}

	#if android
	public static function migrateStorage(newType:String, ?deleteOld:Bool = false):StorageResult
	{
		var oldPath = getStorageDirectory();
		invalidateCache();

		File.saveContent(rootDir + STORAGE_TYPE_FILE, newType);
		var newPath = getStorageDirectory();

		if (oldPath == newPath)
			return OK;

		try
		{
			if (!FileSystem.exists(newPath))
				FileSystem.createDirectory(newPath);

			copyDirectoryRecursive(oldPath, newPath);

			if (deleteOld)
				deleteDirectoryRecursive(oldPath);

			return OK;
		}
		catch (e:Dynamic)
		{
			return FAILED_WRITE;
		}
	}

	private static function copyDirectoryRecursive(from:String, to:String):Void
	{
		if (!FileSystem.exists(from) || !FileSystem.isDirectory(from))
			return;

		if (!FileSystem.exists(to))
			FileSystem.createDirectory(to);

		for (entry in FileSystem.readDirectory(from))
		{
			var fromEntry = Path.join([from, entry]);
			var toEntry = Path.join([to, entry]);

			if (FileSystem.isDirectory(fromEntry))
			{
				copyDirectoryRecursive(fromEntry, toEntry);
			}
			else
			{
				var bytes = File.getBytes(fromEntry);
				File.saveBytes(toEntry, bytes);
			}
		}
	}

	private static function deleteDirectoryRecursive(path:String):Void
	{
		if (!FileSystem.exists(path))
			return;

		for (entry in FileSystem.readDirectory(path))
		{
			var full = Path.join([path, entry]);
			if (FileSystem.isDirectory(full))
				deleteDirectoryRecursive(full);
			else
				FileSystem.deleteFile(full);
		}

		FileSystem.deleteDirectory(path);
	}
	#end

	public static function sanitizeFileName(name:String):String
	{
		var invalidChars = ~/[\\\/:*?"<>|]/g;
		var cleaned = invalidChars.replace(name, '_');
		return cleaned.length > 0 ? cleaned : 'unnamed';
	}

	public static function saveContent(fileName:String, fileData:String, ?alert:Bool = true):StorageResult
	{
		fileName = sanitizeFileName(fileName);

		try
		{
			var savesDir = getSavesPath();
			if (!FileSystem.exists(savesDir))
				FileSystem.createDirectory(savesDir);

			File.saveContent('$savesDir/$fileName', fileData);

			if (alert)
				CoolUtil.showPopUp('$fileName has been saved.', "Success!");

			return OK;
		}
		catch (e:Exception)
		{
			if (alert)
				CoolUtil.showPopUp('$fileName couldn\'t be saved.\n(${e.message})', "Error!");

			return FAILED_WRITE;
		}
	}

	public static function loadContent(fileName:String):Null<String>
	{
		fileName = sanitizeFileName(fileName);
		var path = '${getSavesPath()}/$fileName';

		if (!FileSystem.exists(path))
			return null;

		try
		{
			return File.getContent(path);
		}
		catch (e:Exception)
		{
			return null;
		}
	}

	public static function saveJson(fileName:String, data:Dynamic, ?alert:Bool = true):StorageResult
	{
		try
		{
			var serialized = Json.stringify(data, null, "\t");
			return saveContent(fileName, serialized, alert);
		}
		catch (e:Exception)
		{
			return INVALID_DATA;
		}
	}

	public static function loadJson<T>(fileName:String):Null<T>
	{
		var raw = loadContent(fileName);
		if (raw == null)
			return null;

		try
		{
			return Json.parse(raw);
		}
		catch (e:Exception)
		{
			return null;
		}
	}

	public static function deleteSave(fileName:String):Bool
	{
		fileName = sanitizeFileName(fileName);
		var path = '${getSavesPath()}/$fileName';

		if (!FileSystem.exists(path))
			return false;

		try
		{
			FileSystem.deleteFile(path);
			return true;
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	public static function saveExists(fileName:String):Bool
	{
		fileName = sanitizeFileName(fileName);
		return FileSystem.exists('${getSavesPath()}/$fileName');
	}

	public static function listSaves(?extension:String = null):Array<String>
	{
		var dir = getSavesPath();
		if (!FileSystem.exists(dir))
			return [];

		var entries = FileSystem.readDirectory(dir);
		if (extension == null)
			return entries;

		return entries.filter(function(entry) return entry.toLowerCase().endsWith(extension.toLowerCase()));
	}

	public static function getSaveSize(fileName:String):Int
	{
		fileName = sanitizeFileName(fileName);
		var path = '${getSavesPath()}/$fileName';

		if (!FileSystem.exists(path))
			return -1;

		return FileSystem.stat(path).size;
	}

	public static function getSavesPath():String
	{
		return Path.join([getStorageDirectory(), SAVES_FOLDER]);
	}

	public static function backupSaves():StorageResult
	{
		var savesDir = getSavesPath();
		if (!FileSystem.exists(savesDir))
			return NOT_FOUND;

		try
		{
			var backupsDir = Path.join([getStorageDirectory(), BACKUPS_FOLDER]);
			if (!FileSystem.exists(backupsDir))
				FileSystem.createDirectory(backupsDir);

			var timestamp = DateTools.format(Date.now(), "%Y-%m-%d_%H-%M-%S");
			var targetDir = Path.join([backupsDir, timestamp]);

			#if android
			copyDirectoryRecursive(savesDir, targetDir);
			#else
			FileSystem.createDirectory(targetDir);
			for (entry in FileSystem.readDirectory(savesDir))
			{
				var bytes = File.getBytes(Path.join([savesDir, entry]));
				File.saveBytes(Path.join([targetDir, entry]), bytes);
			}
			#end

			pruneOldBackups(backupsDir);
			return OK;
		}
		catch (e:Dynamic)
		{
			return FAILED_WRITE;
		}
	}

	private static function pruneOldBackups(backupsDir:String):Void
	{
		var entries = FileSystem.readDirectory(backupsDir);
		entries.sort(function(a, b) return a < b ? -1 : (a > b ? 1 : 0));

		while (entries.length > MAX_BACKUPS)
		{
			var oldest = entries.shift();
			var oldestPath = Path.join([backupsDir, oldest]);

			#if android
			deleteDirectoryRecursive(oldestPath);
			#else
			for (file in FileSystem.readDirectory(oldestPath))
				FileSystem.deleteFile(Path.join([oldestPath, file]));
			FileSystem.deleteDirectory(oldestPath);
			#end
		}
	}

	public static function restoreBackup(backupName:String):StorageResult
	{
		var backupsDir = Path.join([getStorageDirectory(), BACKUPS_FOLDER]);
		var sourceDir = Path.join([backupsDir, backupName]);

		if (!FileSystem.exists(sourceDir))
			return NOT_FOUND;

		try
		{
			var savesDir = getSavesPath();
			if (!FileSystem.exists(savesDir))
				FileSystem.createDirectory(savesDir);

			for (entry in FileSystem.readDirectory(sourceDir))
			{
				var bytes = File.getBytes(Path.join([sourceDir, entry]));
				File.saveBytes(Path.join([savesDir, entry]), bytes);
			}

			return OK;
		}
		catch (e:Dynamic)
		{
			return FAILED_READ;
		}
	}

	public static function listBackups():Array<String>
	{
		var backupsDir = Path.join([getStorageDirectory(), BACKUPS_FOLDER]);
		if (!FileSystem.exists(backupsDir))
			return [];

		var entries = FileSystem.readDirectory(backupsDir);
		entries.sort(function(a, b) return a > b ? -1 : (a < b ? 1 : 0));
		return entries;
	}

	public static function isStorageWritable():Bool
	{
		try
		{
			var testPath = Path.join([getStorageDirectory(), '.write_test']);
			File.saveContent(testPath, 'test');
			FileSystem.deleteFile(testPath);
			return true;
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	public static function getDirectorySize(path:String):Int
	{
		if (!FileSystem.exists(path))
			return 0;

		var total = 0;

		if (FileSystem.isDirectory(path))
		{
			for (entry in FileSystem.readDirectory(path))
				total += getDirectorySize(Path.join([path, entry]));
		}
		else
		{
			total = FileSystem.stat(path).size;
		}

		return total;
	}

	#if android
	public static function requestPermissions():Void
	{
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
			AndroidPermissions.requestPermissions(['READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO']);
		else
			AndroidPermissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);

		if (!AndroidEnvironment.isExternalStorageManager())
		{
			if (AndroidVersion.SDK_INT >= AndroidVersionCode.S)
				AndroidSettings.requestSetting('REQUEST_MANAGE_MEDIA');
			AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
		}

		if (!hasRequiredPermissions())
			CoolUtil.showPopUp('If you accepted the permissions you are all good!' + '\nIf you didn\'t then expect a crash' + '\nPress OK to see what happens',
				'Notice!');

		try
		{
			if (!FileSystem.exists(StorageUtil.getStorageDirectory()))
				FileSystem.createDirectory(StorageUtil.getStorageDirectory());
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp('Please create directory to\n' + StorageUtil.getStorageDirectory(true) + '\nPress OK to close the game', 'Error!');
			LimeSystem.exit(1);
		}
	}

	public static function hasRequiredPermissions():Bool
	{
		var granted = AndroidPermissions.getGrantedPermissions();

		return AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU
			? granted.contains('android.permission.READ_MEDIA_IMAGES')
			: granted.contains('android.permission.READ_EXTERNAL_STORAGE');
	}

	public static function checkExternalPaths(?splitStorage = false):Array<String>
	{
		var process = new Process('grep -o "/storage/....-...." /proc/mounts | paste -sd \',\'');
		var paths:String = process.stdout.readAll().toString();
		if (splitStorage)
			paths = paths.replace('/storage/', '');
		return paths.split(',');
	}

	public static function getExternalDirectory(externalDir:String):String
	{
		var daPath:String = '';
		for (path in checkExternalPaths())
			if (path.contains(externalDir))
				daPath = path;

		daPath = Path.addTrailingSlash(daPath.endsWith("\n") ? daPath.substr(0, daPath.length - 1) : daPath);
		return daPath;
	}
	#end
	#end
}

#if android
@:runtimeValue
enum abstract StorageType(String) from String to String
{
	final forcedPath = '/storage/emulated/0/';
	final packageNameLocal = 'com.alialafandy.aliagame';
	final fileLocal = 'AliA_Game';

	var EXTERNAL_DATA = "EXTERNAL_DATA";
	var EXTERNAL_OBB = "EXTERNAL_OBB";
	var EXTERNAL_MEDIA = "EXTERNAL_MEDIA";
	var EXTERNAL = "EXTERNAL";

	public static function fromStr(str:String):StorageType
	{
		final EXTERNAL_DATA = AndroidContext.getExternalFilesDir();
		final EXTERNAL_OBB = AndroidContext.getObbDir();
		final EXTERNAL_MEDIA = AndroidEnvironment.getExternalStorageDirectory() + '/Android/media/' + lime.app.Application.current.meta.get('packageName');
		final EXTERNAL = AndroidEnvironment.getExternalStorageDirectory() + '/.' + lime.app.Application.current.meta.get('file');

		return switch (str)
		{
			case "EXTERNAL_DATA": EXTERNAL_DATA;
			case "EXTERNAL_OBB": EXTERNAL_OBB;
			case "EXTERNAL_MEDIA": EXTERNAL_MEDIA;
			case "EXTERNAL": EXTERNAL;
			default: StorageUtil.getExternalDirectory(str) + '.' + fileLocal;
		}
	}

	public static function fromStrForce(str:String):StorageType
	{
		final EXTERNAL_DATA = forcedPath + 'Android/data/' + packageNameLocal + '/files';
		final EXTERNAL_OBB = forcedPath + 'Android/obb/' + packageNameLocal;
		final EXTERNAL_MEDIA = forcedPath + 'Android/media/' + packageNameLocal;
		final EXTERNAL = forcedPath + '.' + fileLocal;

		return switch (str)
		{
			case "EXTERNAL_DATA": EXTERNAL_DATA;
			case "EXTERNAL_OBB": EXTERNAL_OBB;
			case "EXTERNAL_MEDIA": EXTERNAL_MEDIA;
			case "EXTERNAL": EXTERNAL;
			default: StorageUtil.getExternalDirectory(str) + '.' + fileLocal;
		}
	}
}
#end
