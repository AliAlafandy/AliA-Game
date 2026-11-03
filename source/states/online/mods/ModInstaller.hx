package states.online.mods;

#if sys
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.zip.Entry;
import haxe.zip.Reader;
import haxe.Json;

import sys.FileSystem;
import sys.io.File;

using StringTools;

typedef ModMeta = {
    var id:String;
    var name:String;
    var version:String;
    @:optional var author:String;
    @:optional var description:String;
}

enum InstallResult {
    Success(meta:ModMeta);
    AlreadyInstalled(meta:ModMeta);
    InvalidZip(reason:String);
    MissingMeta;
    Failed(reason:String);
}

class ModInstaller {

    static inline var MODS_DIR_NAME:String = "mods";
    static inline var META_FILENAME:String = "mod.json";

    public static function install(zipPath:String, ?overwrite:Bool = false, ?providedMeta:ModMeta = null):InstallResult {
        if (!FileSystem.exists(zipPath)) {
            return Failed("ZIP file not found: " + zipPath);
        }

        var entries:List<Entry>;
        try {
            var input = File.read(zipPath, true);
            entries = Reader.readZip(input);
            input.close();
        } catch (e:Dynamic) {
            return InvalidZip("Could not read ZIP: " + Std.string(e));
        }

        var modsDir = getModsDirectory();
        var tempDir = modsDir + "/.tmp_install_" + Std.int(Date.now().getTime());

        try {
            extractEntries(entries, tempDir);
        } catch (e:Dynamic) {
            removeDirectory(tempDir);
            return Failed("Extraction failed: " + Std.string(e));
        }

        try {
            FileSystem.deleteFile(zipPath);
        } catch (e:Dynamic) {}

        var modDirWithMeta = findModDirectoryWithMeta(tempDir);
        var actualModDir = modDirWithMeta != null ? modDirWithMeta : tempDir;

        var meta:ModMeta = null;
        try {
            if (FileSystem.exists(actualModDir + "/" + META_FILENAME)) {
                var content = File.getContent(actualModDir + "/" + META_FILENAME);
                meta = normalizeMeta(tjson.TJSON.parse(content), Path.withoutDirectory(actualModDir));
            }
        } catch (e:Dynamic) {
            trace("[ModInstaller] Could not parse mod.json: " + Std.string(e));
        }

        if (meta == null && providedMeta != null) {
            meta = providedMeta;
            try {
                File.saveContent(actualModDir + "/" + META_FILENAME, Json.stringify(meta));
            } catch (e:Dynamic) {
                removeDirectory(tempDir);
                return Failed("Could not write mod.json: " + Std.string(e));
            }
        }

        if (meta == null || meta.id == null || meta.name == null || meta.version == null) {
            removeDirectory(tempDir);
            return MissingMeta;
        }

        var targetDir = modsDir + "/" + meta.id;

        if (FileSystem.exists(targetDir) && !overwrite) {
            removeDirectory(tempDir);
            return AlreadyInstalled(meta);
        }

        try {
            if (FileSystem.exists(targetDir)) {
                removeDirectory(targetDir);
            }

            if (actualModDir == tempDir) {
                FileSystem.rename(tempDir, targetDir);
            } else {
                FileSystem.createDirectory(targetDir);
                moveDirectoryContents(actualModDir, targetDir);
                removeDirectory(tempDir);
            }
        } catch (e:Dynamic) {
            removeDirectory(tempDir);
            return Failed("Could not finalize install: " + Std.string(e));
        }

        return Success(meta);
    }

    public static function uninstall(modId:String):Bool {
        var targetDir = getModsDirectory() + "/" + modId;
        if (!FileSystem.exists(targetDir)) return false;

        try {
            removeDirectory(targetDir);
            return true;
        } catch (e:Dynamic) {
            return false;
        }
    }

    public static function readMeta(modId:String):Null<ModMeta> {
        var metaPath = getModsDirectory() + "/" + modId + "/" + META_FILENAME;
        if (!FileSystem.exists(metaPath)) return null;

        try {
            return normalizeMeta(tjson.TJSON.parse(File.getContent(metaPath)), modId);
        } catch (e:Dynamic) {
            trace("[ModInstaller] Invalid mod.json: " + Std.string(e));
            return null;
        }
    }

    static function normalizeMeta(raw:Dynamic, fallbackId:String):Null<ModMeta>
    {
        if (raw == null) return null;
        var data:Dynamic = Reflect.hasField(raw, "metaData") ? Reflect.field(raw, "metaData") : raw;
        if (data == null) return null;

        var id = getMetaString(data, "id", getMetaString(data, "modId", fallbackId));
        var name = getMetaString(data, "name", fallbackId);
        var version = getMetaString(data, "modVersion", getMetaString(data, "version", "1.0.0"));
        var author = getMetaString(data, "author", "Unknown author");
        var description = getMetaString(data, "description", "");
        if (id == null || id.length == 0 || name == null || name.length == 0) return null;

        return { id: id, name: name, version: version, author: author, description: description };
    }

    static function getMetaString(data:Dynamic, field:String, fallback:String):String
    {
        if (data != null && Reflect.hasField(data, field))
        {
            var value = Reflect.field(data, field);
            if (value != null && Std.string(value).length > 0) return Std.string(value);
        }
        return fallback;
    }

    static function findModDirectoryWithMeta(dir:String):Null<String> {
        if (FileSystem.exists(dir + "/" + META_FILENAME)) {
            return dir;
        }

        for (item in FileSystem.readDirectory(dir)) {
            var fullPath = dir + "/" + item;
            if (FileSystem.isDirectory(fullPath)) {
                if (FileSystem.exists(fullPath + "/" + META_FILENAME)) {
                    return fullPath;
                }
                var nested = findModDirectoryWithMeta(fullPath);
                if (nested != null) {
                    return nested;
                }
            }
        }
        return null;
    }

    static function extractEntries(entries:List<Entry>, targetDir:String):Void {
        FileSystem.createDirectory(targetDir);

        for (entry in entries) {
            var name = normalizeEntryName(entry.fileName);
            if (name == "" || name.endsWith("/") || name.indexOf("__MACOSX") != -1) continue;

            if (name.indexOf("..") != -1) {
                throw "Unsafe path in ZIP entry: " + name;
            }

            var outPath = targetDir + "/" + name;
            var outDir = Path.directory(outPath);
            if (outDir != "" && !FileSystem.exists(outDir)) {
                FileSystem.createDirectory(outDir);
            }

            var bytes:Bytes = entry.data != null ? haxe.zip.Reader.unzip(entry) : Bytes.alloc(0);
            File.saveBytes(outPath, bytes);
        }
    }

    static function moveDirectoryContents(source:String, dest:String):Void {
        for (item in FileSystem.readDirectory(source)) {
            var srcPath = source + "/" + item;
            var destPath = dest + "/" + item;
            if (FileSystem.isDirectory(srcPath)) {
                FileSystem.createDirectory(destPath);
                moveDirectoryContents(srcPath, destPath);
            } else {
                File.copy(srcPath, destPath);
            }
        }
    }

    static function normalizeEntryName(fileName:String):String {
        return fileName.split("\\").join("/");
    }

    static function removeDirectory(dir:String):Void {
        if (!FileSystem.exists(dir)) return;

        for (item in FileSystem.readDirectory(dir)) {
            var fullPath = dir + "/" + item;
            if (FileSystem.isDirectory(fullPath)) {
                removeDirectory(fullPath);
            } else {
                FileSystem.deleteFile(fullPath);
            }
        }
        FileSystem.deleteDirectory(dir);
    }

    static function getModsDirectory():String {
        return #if mobile StorageUtil.getStorageDirectory() + #end MODS_DIR_NAME;
    }
}
#end
