package substates;

import states.options.BaseOptionsMenu;

class GameplaySettingsSubState extends BaseOptionsMenu
{
    public function new()
    {
        heading.text = "Gameplay Settings";
        super("GameplaySettings");
    }

    override public function buildRows():Void
    {
        addBool(
            "Time Limit",
            "timeLimit",
            "Enable Time to Slow down."
        );

        addBool(
            "Debug Menu",
            "debugMenu",
            "Enable cheats on Main Play."
        );

        addBool(
            "Infinite Life",
            "infiniteLife",
            "Make lifes infinite."
        );

        addBool(
            "Infinite Power",
            "infinitePower",
            "Make power infinite."
        );
    }
}
