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
		var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/background'));
		add(bg);

		var charPlace:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/Selects/char_place'));
		add(charPlace);

        txt = new FlxText(0, 0, 0, "", 16);
        txt.screenCenter();
        add(txt);
        updateChar();

        #if mobile
		addCustomDPad('EXIST', 'MENU');
		addCustomDPadCam();
		#end
    }

    function updateChar() {
        txt.text = "Select Character:\n< " + chars[index] + " >\n\nENTER to Play";
        txt.screenCenter();
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.music('select_character', 'menus'));

        if (controls.UI_LEFT_P) index--;
        if (controls.UI_RIGHT_P) index++;
        index = (index + chars.length) % chars.length;
        updateChar();

        if (controls.ACCEPT) {
            // Save selected character here
            GameState.switchState(new PlayState());
			FlxG.sound.music.volume = 0;
        }

        if (controls.BACK) {
            GameState.switchState(new SelectState());
        }
    }
}
