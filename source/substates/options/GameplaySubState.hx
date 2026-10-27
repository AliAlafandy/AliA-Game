package substates.options;

import states.options.BaseOptionsMenu;

class GameplaySubState extends BaseOptionsMenu
{
    public function new() super("Gameplay");

    override public function buildRows():Void
    {
                addBool("Down scroll", "downscroll", "Place gameplay notes at the bottom when supported.");
                addFloat("Safe frames", "safeFrames", 0.0, 20.0, 0.5, "Input timing window.");
                addBool("Instakill on miss", "instakill", "Fail immediately after a miss.");
                addBool("Practice mode", "practice", "Enable practice gameplay.");
                addBool("Botplay", "botplay", "Enable automatic play where supported.");
                addBool("Opponent play", "opponentplay", "Enable opponent-controlled gameplay where supported.");
    }
}
