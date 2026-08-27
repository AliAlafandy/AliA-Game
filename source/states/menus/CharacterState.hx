package states.menus;

class CharacterState extends GameState {
    var index:Int = 0;
    var chars:Array<String> = [
        "Ellawy",
        "Hamedo",
        "Zezo",
        "Shaban",
        "Ellawy+"
    ];
    var txt:FlxText;

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
        txt = new FlxText(0, 0, 0, "", 16);
        txt.screenCenter();
        add(txt);
        updateChar();

        #if mobile
		addCustomDPad();
		addCustomDPadCam();
		#end
    }

    function updateChar() {
        txt.text = "Select Character:\n< " + chars[index] + " >\n\nENTER to Play";
        txt.screenCenter();
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.keys.justPressed.LEFT) index--;
        if (FlxG.keys.justPressed.RIGHT) index++;
        index = (index + chars.length) % chars.length;
        updateChar();

        if (controls.ACCEPT) {
            // Save selected character here
            FlxG.switchState(new PlayState());
        }

        if (controls.BACK) {
            FlxG.switchState(new SelectState());
        }
    }
}
