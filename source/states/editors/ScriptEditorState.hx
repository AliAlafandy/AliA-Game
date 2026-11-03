package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.ui.AUIBox;
import flixel.ui.AUIButton;
import openfl.events.TextEvent;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

#if sys
import sys.FileSystem;
import sys.io.File;
#end
using StringTools;

/**
 * Visual Ellawy workspace: file browser, open-file tabs, code canvas,
 * keyboard text input, completion hints and save controls.
 * This editor handles .ellawy only; it does not embed Lua or OpenFL TextField.
 */
class ScriptEditorState extends GameState
{
    private var files:Array<String> = [];
    private var tabs:Array<String> = [];
    private var selectedFile:Int = -1;
    private var selectedTab:Int = -1;
    private var source:String = "";
    private var dirty:Bool = false;
    private var buffers:Map<String, String> = new Map();
    private var dirtyPaths:Map<String, Bool> = new Map();

    private var fileText:FlxText;
    private var tabText:FlxText;
    private var codeText:FlxText;
    private var status:FlxText;
    private var completion:FlxText;
    private var lineNumbers:FlxText;

    #if sys
    private var rootPath:String = "";
    #end

    #if mobile
    public var manager:MobileInputManager;
    #end

    public function new():Void
    {
        super();
        #if mobile
        manager = new MobileInputManager();
        #end
    }

    override public function create():Void
    {
        super.create();
        FlxG.camera.bgColor = 0xFF101722;

        add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF101722));
        add(new FlxSprite(0, 0).makeGraphic(FlxG.width, 48, 0xFF202D40));

        var heading = new FlxText(14, 13, FlxG.width - 28, "ELLAWY WORKSPACE     .ellawy", 20);
        heading.setFormat(null, 20, FlxColor.WHITE, LEFT);
        add(heading);

        var filePanelWidth = Std.int(FlxG.width * 0.28);
        add(new AUIBox(10, 60, filePanelWidth, FlxG.height - 126, "FILES"));
        add(new AUIBox(Std.int(FlxG.width * 0.30), 92, Std.int(FlxG.width * 0.69) - 10, FlxG.height - 158));

        fileText = new FlxText(20, 96, filePanelWidth - 22, "", 12);
        fileText.setFormat("_typewriter", 12, FlxColor.WHITE, LEFT);
        add(fileText);

        tabText = new FlxText(Std.int(FlxG.width * 0.30) + 8, 62, FlxG.width * 0.68, "No file open", 12);
        tabText.setFormat(null, 12, FlxColor.YELLOW, LEFT);
        add(tabText);

        lineNumbers = new FlxText(Std.int(FlxG.width * 0.30) + 12, 102, 38, "1", 12);
        lineNumbers.setFormat("_typewriter", 12, 0xFF6F829B, RIGHT);
        add(lineNumbers);

        codeText = new FlxText(Std.int(FlxG.width * 0.30) + 58, 102, FlxG.width * 0.66, "", 14);
        codeText.setFormat("_typewriter", 14, 0xFFE5EDF7, LEFT);
        add(codeText);

        completion = new FlxText(Std.int(FlxG.width * 0.30) + 58, FlxG.height - 82, FlxG.width * 0.66, "", 12);
        completion.setFormat(null, 12, FlxColor.YELLOW, LEFT);
        add(completion);

        status = new FlxText(12, FlxG.height - 28, FlxG.width - 24, "UP/DOWN files | ENTER open | CTRL+S save | CTRL+TAB switch tabs | type in editor | ESC back", 12);
        status.setFormat(null, 12, 0xFF9EADC2, LEFT);
        add(status);

        #if sys
        rootPath = Paths.mods();
        #end
        scanFiles();
        refreshFiles();
        refreshCode();

        // Text is captured by the state while the visible code canvas remains a Flixel UI.
        #if (js || sys)
        FlxG.stage.addEventListener(TextEvent.TEXT_INPUT, onTextInput);
        FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        #end

        addEditorButton(12, FlxG.height - 66, "OPEN", function() {
            if (selectedFile == -1) createScript();
            else if (files.length > 0) openFile(files[selectedFile]);
        });
        addEditorButton(102, FlxG.height - 66, "SAVE", saveFile);
        addEditorButton(192, FlxG.height - 66, "NEW", createScript);
        addEditorButton(282, FlxG.height - 66, "BACK", function() GameState.switchState(new EditorState()));
    }

    private function addEditorButton(x:Float, y:Float, label:String, callback:Void->Void):Void
    {
        var button = new AUIButton(x, y, 82, 28, label, callback);
        editorButtons.push(button);
        add(button);
    }

    private function scanFiles():Void
    {
        files = [];
        #if sys
        #if MODS_ALLOWED
        if (FileSystem.exists(rootPath))
            for (mod in FileSystem.readDirectory(rootPath))
            {
                var folder = haxe.io.Path.join([rootPath, mod]);
                var scripts = haxe.io.Path.join([folder, "scripts"]);
                if (FileSystem.isDirectory(folder) && FileSystem.exists(scripts)) scanDirectory(scripts);
            }
        #end
        var shared = Paths.getSharedPath() + "scripts/";
        if (FileSystem.exists(shared)) scanDirectory(shared);
        #end
        files.sort(Reflect.compare);
    }

    private function scanDirectory(dir:String):Void
    {
        #if sys
        try for (entry in FileSystem.readDirectory(dir))
        {
            var path = haxe.io.Path.join([dir, entry]);
            if (FileSystem.isDirectory(path)) scanDirectory(path);
            else if (entry.toLowerCase().endsWith(".ellawy") && !files.contains(path)) files.push(path);
        } catch (e:Dynamic) trace("[ScriptEditor] " + e);
        #end
    }

    private function refreshFiles():Void
    {
        var lines:Array<String> = [selectedFile == -1 ? "> + NEW SCRIPT" : "+ NEW SCRIPT"];
        for (i in 0...files.length)
        {
            var marker = (i == selectedFile) ? "> " : "  ";
            var name = files[i].split("/").pop();
            lines.push(marker + name);
        }
        fileText.text = lines.join("\n");
    }

    private function refreshCode():Void
    {
        if (selectedTab < 0 || selectedTab >= tabs.length)
        {
            codeText.text = "// Select or create an .ellawy file";
            lineNumbers.text = "1";
            tabText.text = "No file open";
            return;
        }
        var path = tabs[selectedTab];
        var tabNames:Array<String> = [];
        for (i in 0...tabs.length)
        {
            var label = tabs[i].split("/").pop();
            if (dirtyPaths.exists(tabs[i]) && dirtyPaths.get(tabs[i])) label += "*";
            tabNames.push(i == selectedTab ? "[" + label + "]" : label);
        }
        tabText.text = tabNames.join("   |   ");
        var shown = source;
        if (shown.length == 0) shown = "// Start writing Ellawy here";
        codeText.text = shown + (dirty ? "▌" : "");
        var count = source.split("\n").length;
        var nums:Array<String> = [];
        for (i in 1...(count + 1)) nums.push(Std.string(i));
        lineNumbers.text = nums.join("\n");
        updateCompletion();
    }

    private function updateCompletion():Void
    {
        var last = source.substr(source.lastIndexOf("\n") + 1).trim();
        var hints:Array<String> = [];
        if ("function".startsWith(last.toLowerCase()) || last == "fun")
            hints = ["function name() { ... } end", "onCreate", "onUpdate", "onGame"];
        else if (last.endsWith("."))
            hints = ["PlayState", "FlxG", "Paths", "Mods"];
        else if (last.length > 0 && last.length < 12)
            hints = ["function", "if", "else", "while", "return", "end"];
        completion.text = hints.length > 0 ? "Suggestions: " + hints.join("   ") : "";
    }

    private function openFile(path:String):Void
    {
        #if sys
        if (!path.toLowerCase().endsWith(".ellawy")) return;
        try
        {
            if (!tabs.contains(path)) tabs.push(path);
            if (selectedTab >= 0 && selectedTab < tabs.length) { buffers.set(tabs[selectedTab], source); dirtyPaths.set(tabs[selectedTab], dirty); }
            selectedTab = tabs.indexOf(path);
            source = buffers.exists(path) ? buffers.get(path) : File.getContent(path);
            dirty = dirtyPaths.exists(path) && dirtyPaths.get(path);
            refreshCode();
            status.text = "Opened " + path;
        }
        catch (e:Dynamic) status.text = "Open failed: " + Std.string(e);
        #end
    }

    private function saveFile():Void
    {
        #if sys
        if (selectedTab < 0 || selectedTab >= tabs.length) return;
        var path = tabs[selectedTab];
        if (!path.toLowerCase().endsWith(".ellawy")) return;
        try
        {
            File.saveContent(path, source);
            dirty = false;
            dirtyPaths.set(path, false);
            buffers.set(path, source);
            status.text = "Saved " + path;
            refreshCode();
        }
        catch (e:Dynamic) status.text = "Save failed: " + Std.string(e);
        #end
    }

    private function createScript():Void
    {
        #if sys
        #if MODS_ALLOWED
        var modFolder:String = null;
        if (FileSystem.exists(rootPath))
            for (entry in FileSystem.readDirectory(rootPath))
            {
                var candidate = haxe.io.Path.join([rootPath, entry]);
                if (FileSystem.isDirectory(candidate)) { modFolder = candidate; break; }
            }
        if (modFolder == null) { status.text = "Create a mod folder first."; return; }
        var dir = haxe.io.Path.join([modFolder, "scripts"]);
        if (!FileSystem.exists(dir)) FileSystem.createDirectory(dir);
        var path = haxe.io.Path.join([dir, "new_script.ellawy"]);
        var i = 1;
        while (FileSystem.exists(path)) { path = haxe.io.Path.join([dir, "new_script_" + i + ".ellawy"]); i++; }
        File.saveContent(path, "// Ellawy mod script\n\nfunction onGame()\n{\n}\nend\n");
        scanFiles();
        selectedFile = files.indexOf(path);
        refreshFiles();
        openFile(path);
        #else
        status.text = "Mod support is disabled.";
        #end
        #end
    }

    private function onTextInput(event:TextEvent):Void
    {
        if (selectedTab < 0 || event.text == null) return;
        var text = event.text;
        for (i in 0...text.length)
        {
            var code = text.charCodeAt(i);
            if (code >= 32 || code == 10 || code == 13) source += text.charAt(i);
        }
        dirty = true;
        if (selectedTab >= 0) { buffers.set(tabs[selectedTab], source); dirtyPaths.set(tabs[selectedTab], true); }
        refreshCode();
    }

    private function onKeyDown(event:KeyboardEvent):Void
    {
        if (event.ctrlKey && event.keyCode == Keyboard.S) { event.preventDefault(); saveFile(); return; }
        if (event.ctrlKey && event.keyCode == Keyboard.TAB) { event.preventDefault(); return; }
        if (event.keyCode == Keyboard.ESCAPE) { event.preventDefault(); GameState.switchState(new EditorState()); return; }
        if (selectedTab < 0) return;
        if (event.keyCode == Keyboard.BACKSPACE)
        {
            if (source.length > 0) source = source.substr(0, source.length - 1);
            dirty = true;
            if (selectedTab >= 0) { buffers.set(tabs[selectedTab], source); dirtyPaths.set(tabs[selectedTab], true); }
            refreshCode();
        }
        else if (event.keyCode == Keyboard.ENTER)
        {
            source += "\n";
            dirty = true;
            buffers.set(tabs[selectedTab], source);
            dirtyPaths.set(tabs[selectedTab], true);
            refreshCode();
        }
        else if (event.keyCode == Keyboard.TAB)
        {
            event.preventDefault();
            source += "    ";
            dirty = true;
            buffers.set(tabs[selectedTab], source);
            dirtyPaths.set(tabs[selectedTab], true);
            refreshCode();
        }
    }

    private function switchTab():Void
    {
        if (tabs.length < 2 || selectedTab < 0) return;
        buffers.set(tabs[selectedTab], source);
        dirtyPaths.set(tabs[selectedTab], dirty);
        selectedTab = (selectedTab + 1) % tabs.length;
        var path = tabs[selectedTab];
        source = buffers.exists(path) ? buffers.get(path) : "";
        dirty = dirtyPaths.exists(path) && dirtyPaths.get(path);
        refreshCode();
    }



    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (selectedTab < 0)
        {
            if (controls.GAME_UP_P && files.length > 0) { selectedFile = FlxMath.wrap(selectedFile - 1, -1, files.length - 1); refreshFiles(); }
            if (controls.GAME_DOWN_P && files.length > 0) { selectedFile = FlxMath.wrap(selectedFile + 1, -1, files.length - 1); refreshFiles(); }
            if (controls.ACCEPT)
            {
                if (selectedFile < 0) createScript();
                else if (files.length > 0) openFile(files[selectedFile]);
            }
        }
        if (FlxG.keys.justPressed.N) createScript();
        if (FlxG.keys.justPressed.F5) saveFile();
        if (FlxG.keys.justPressed.TAB && FlxG.keys.pressed.CONTROL) switchTab();
    }

    override public function destroy():Void
    {
        #if (js || sys)
        FlxG.stage.removeEventListener(TextEvent.TEXT_INPUT, onTextInput);
        FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        #end
        super.destroy();
    }
}
