package data.backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.display.BitmapData;
import openfl.utils.Assets;
import haxe.crypto.Base64;
import haxe.io.Bytes;

using StringTools;

/**
 * Runtime reader for assets/levels/ATown/ATown.bin.
 * The packed file contains the original PNG byte streams, preserving each
 * source filename and the exact PNG dimensions/pixels.
 */
class ATownAssets
{
    private static var decoded:Map<String, BitmapData> = new Map();
    private static var loaded:Bool = false;

    private static function readArchive():Void
    {
        if (loaded) return;
        loaded = true;
        var path = Paths.getSharedPath("levels/ATown/ATown.bin");
        if (!Assets.exists(path))
        {
            trace("[ATownAssets] Missing packed asset: " + path);
            return;
        }

        try
        {
            var content = Assets.getText(path);
            var lines = content.split("\n");
            if (lines.length == 0 || lines[0].trim() != "ATOWNBIN|1")
                throw "Unsupported ATown archive version";

            for (i in 1...lines.length)
            {
                var line = lines[i].trim();
                if (line.length == 0) continue;
                var splitAt = line.indexOf("|");
                if (splitAt <= 0) continue;

                var name = line.substr(0, splitAt);
                if (!name.toLowerCase().endsWith(".png")) continue;

                var encoded = line.substr(splitAt + 1);
                var bytes:Bytes = Base64.decode(encoded);
                var bitmap = BitmapData.fromBytes(bytes);
                if (bitmap != null) decoded.set(name, bitmap);
            }
        }
        catch (e:Dynamic)
        {
            trace("[ATownAssets] Could not read ATown.bin: " + Std.string(e));
        }
    }

    public static function addTo(group:FlxTypedGroup<FlxSprite>):Void
    {
        if (group == null) return;
        readArchive();

        var order = ["sky.png", "sun.png", "clouds.png", "buildings.png", "sidewalk.png", "street.png"];
        for (name in order)
        {
            var bitmap = decoded.get(name);
            if (bitmap == null) continue;

            var sprite = new FlxSprite();
            sprite.loadGraphic(bitmap);
            sprite.x = 0;

            switch (name)
            {
                case "sky.png": sprite.y = 0; sprite.scrollFactor.set(0.05, 0.05);
                case "sun.png": sprite.y = 60; sprite.scrollFactor.set(0.08, 0.08);
                case "clouds.png": sprite.y = 40; sprite.scrollFactor.set(0.12, 0.08);
                case "buildings.png": sprite.y = 150; sprite.scrollFactor.set(0.35, 0.35);
                case "sidewalk.png": sprite.y = FlxG.height - bitmap.height - 48; sprite.scrollFactor.set(0.8, 0.8);
                case "street.png": sprite.y = FlxG.height - bitmap.height; sprite.scrollFactor.set(1, 1);
            }
            group.add(sprite);
        }
    }

}
