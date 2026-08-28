package states;

import states.menus.SelectState;

import states.OnlineState;

#if MODS_ALLOWED
import states.menus.ModsState;
#end

class lMenuState extends GameState {
    var index:Int = 0;
    var items:Array<String> = [
        "Play",
        "Online",

        #if MODS_ALLOWED
        "Mods",
        #end

        "Options",
        "Quit"
    ];
    var texts:Array<FlxText> = [];

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

    override public function create() {
        for (i in 0...items.length) {
            var t = new FlxText(0, 120 + i * 30, 0, items[i], 14);
            t.screenCenter(X);
            add(t);
            texts.push(t);
        }
        updateSel();
    }

    function updateSel() {
        for (i in 0...texts.length)
            texts[i].color = (i == index) ? 0xFFFFFF00 : 0xFFFFFFFF;
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.keys.justPressed.UP) index--;
        if (FlxG.keys.justPressed.DOWN) index++;
        index = (index + items.length) % items.length;
        updateSel();

        if (FlxG.keys.justPressed.ENTER) {
            switch(items[index]) {
                case "Play": GameState.switchState(new SelectState());

                case 'Online': GameState.switchState(new OnlineState());

                #if MODS_ALLOWED
                case "Mods": GameState.switchState(new ModsState());
                #end

                case "Options": GameState.switchState(new OptionsState());
                    
                case "Quit": LimeSystem.exit(1); //FlxG.exit();
            }
        }
    }
}
