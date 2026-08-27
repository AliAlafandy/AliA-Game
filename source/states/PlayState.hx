package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;

import data.objects.Player;

#if mobile
import mobile.data.MobileInputManager;
#end

#if DISCORD_ALLOWED
import data.DiscordRPC;
#end

#if HSCRIPT_ALLOWED
import data.scripts.HScript;
#end

class PlayState extends GameState
{
    public var player:Player;

    private var elapsedTime:Float = 0;
    private var rpcTimer:Float = 0;

    #if mobile
    public var manager:MobileInputManager;
    #end

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	public var instancesExclude:Array<String> = [];
	#end

	public var debugGroup:FlxTypedGroup<flixel.text.FlxText>;

	public var instance:Playstate;

    public function new():Void
    {
        super();
		instance = this;
        #if mobile
        manager = new MobileInputManager();
        #end
    }

    override public function create():Void
    {
        super.create();

		debugGroup = new flixel.group.FlxTypedGroup.FlxTypedGroup<flixel.text.FlxText>();
		add(debugGroup);

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/'))
		{
			for (file in Paths.readDirectory(folder))
			{		
				#if HSCRIPT_ALLOWED
				var lowerFile = file.toLowerCase();
				if (lowerFile.endsWith('.ellawy'))
				{
					initHScript(folder + file);
				}
				#end
			}
		}
		
        FlxG.camera.bgColor = FlxColor.BLACK;

        player = new Player(0, 0, 'Ellawy', true);
        player.screenCenter();
        add(player);

        var title:FlxText = new FlxText(
            0,
            20,
            FlxG.width,
            'ALI ALAFANDY GAME',
            24
        );
        title.setFormat(null, 24, FlxColor.WHITE, CENTER);
        add(title);

        var help:FlxText = new FlxText(
            0,
            FlxG.height - 50,
            FlxG.width,
            'ARROW KEYS / WASD    PAUSE: ESC',
            16
        );
        help.setFormat(null, 16, FlxColor.WHITE, CENTER);
        add(help);

        #if mobile
		addCustomDPad();
		addCustomDPadCam();
		#end

        #if DISCORD_ALLOWED
        DiscordClient.changePresence('Play - Ali Alafandy Game',null);
        #end
    }

	#if HSCRIPT_ALLOWED
	public function addTextToDebug(text:String, color:FlxColor) {
		if (debugGroup == null) return;

		var newText:flixel.text.FlxText = debugGroup.recycle(flixel.text.FlxText, function() {
			var txt = new flixel.text.FlxText(10, 0, 0, "", 12);
			txt.setFormat(null, 12, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			return txt;
		});

		newText.text = text;
		newText.color = color;
		newText.alpha = 1;
		newText.setPosition(10, 8);

		debugGroup.forEachAlive(function(spr:flixel.text.FlxText) {
			if (spr != newText) {
				spr.y += newText.height + 2;
			}
		});

		debugGroup.add(newText);

		flixel.util.FlxTimer.wait(6, function() {
			if (newText != null && newText.alive) {
				newText.kill();
			}
		});

		Sys.println(text);
	}
	#end

    override public function update(elapsed:Float):Void
    {
        elapsedTime += elapsed;
        rpcTimer += elapsed;

        handleInput();

        #if DISCORD_ALLOWED
        if (rpcTimer >= 1)
        {
            rpcTimer = 0;
            DiscordClient.changePresence('Playing Ali-A Game\n' + 'Play - ATown Act1' + "Time :" + Std.int(elapsedTime) ,null);
        }
        #end

        super.update(elapsed);
    }

    private function handleInput():Void
    {
        if (controls.BACK)
        {
            FlxG.switchState(new MenuState());
        }
    }

	#if HSCRIPT_ALLOWED
	public function startScriptsNamed(scriptFile:String)
	{
		if (!scriptFile.toLowerCase().endsWith('.ellawy'))
		{
			var lastDot = scriptFile.lastIndexOf('.');
			if (lastDot != -1)
				scriptFile = scriptFile.substr(0, lastDot) + '.ellawy';
			else
				scriptFile += '.ellawy';
		}

		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			if (SScript.global.exists(scriptToLoad)) return false;

			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String)
	{
		try
		{
			var finalFilePath:String = file;

			#if ELLAWY_ALLOWED
			if (file.toLowerCase().endsWith('.ellawy'))
			{
				var sourceCode = sys.io.File.getContent(file);
				var compiledHaxe = ellawy.Compiler.compileSource(sourceCode, file);
				
				var cachePath = file.substr(0, file.lastIndexOf('.')) + '_cache.hx';
				sys.io.File.saveContent(cachePath, compiledHaxe);
				finalFilePath = cachePath;
			}
			#end

			var newScript:HScript = new HScript(null, finalFilePath);
			if(newScript.parsingException != null)
			{
				addTextToDebug('ERROR ON LOADING ($file): ${newScript.parsingException.message}', FlxColor.RED);
				newScript.destroy();
				return;
			}

			hscriptArray.push(newScript);
			if(newScript.exists('onCreate'))
			{
				var callValue = newScript.call('onCreate');
				if(!callValue.succeeded)
				{
					for (e in callValue.exceptions)
					{
						if (e != null)
						{
							var len:Int = e.message.indexOf('\n') + 1;
							if(len <= 0) len = e.message.length;
								addTextToDebug('ERROR ($file: onCreate) - ${e.message.substr(0, len)}', FlxColor.RED);
						}
					}

					newScript.destroy();
					hscriptArray.remove(newScript);
					trace('failed to initialize script interp!!! ($file)');
				}
				else trace('initialized script interp successfully: $file');
			}

		}
		catch(e)
		{
			var len:Int = e.message.indexOf('\n') + 1;
			if(len <= 0) len = e.message.length;
			addTextToDebug('ERROR - ' + e.message.substr(0, len), FlxColor.RED);
			var newScript:HScript = cast (SScript.global.get(file), HScript);
			if(newScript != null)
			{
				newScript.destroy();
				hscriptArray.remove(newScript);
			}
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = 0;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [];

		return callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = null;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;
			
		for(i in 0...len) {
			var script:HScript = hscriptArray[i];
			if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var myValue:Dynamic = null;
			try {
				var callValue = script.call(funcToCall, args);
				if(!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if(e != null)
					{
						var len:Int = e.message.indexOf('\n') + 1;
						if(len <= 0) len = e.message.length;
						addTextToDebug('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, len), FlxColor.RED);
					}
				}
				else
				{
					myValue = callValue.returnValue;
					if(myValue != null && !excludeValues.contains(myValue))
						returnVal = myValue;
				}
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin))
				continue;

			if(!instancesExclude.contains(variable))
				instancesExclude.push(variable);
			script.set(variable, arg);
		}
		#end
	}

    override public function destroy():Void
    {
        player = null;

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null)
			{
				script.call('onDestroy');
				
				#if (sys && ELLAWY_ALLOWED)
				var originPath:String = script.origin;
				if (originPath != null && originPath.endsWith('_cache.hx'))
				{
					if (sys.FileSystem.exists(originPath))
					{
						try {
							sys.FileSystem.deleteFile(originPath);
						} catch(e:Dynamic) {
							trace('Failed to delete ellawy cache file: $e');
						}
					}
				}
				#end

				script.destroy();
			}

			while (hscriptArray.length > 0)
					hscriptArray.pop();
		#end

        super.destroy();
    }
}
