package substates.options;

import states.options.BaseOptionsMenu;

class ControlsSubState extends BaseOptionsMenu
{
    public function new() super("Controls");

    override public function buildRows():Void
    {
                addString("Controls color", "controlsColor", ["Yellow", "Blue", "Red", "Green", "Purple", "White"], "Color theme for mobile controls.");
                addInt("Controls size", "controlsSize", 1, 4, 1, "Scale of mobile controls.");
                addFloat("Controls alpha", "controlsAlpha", 0.1, 1.0, 0.1, "Opacity of mobile controls.");
                addBool("Vibration", "vibration", "Enable supported device vibration.");
                addString("Hitbox style", "hitboxType", ["Gradient", "Normal", "No Gradient"], "Mobile touch hitbox style.");
                addString("Extra buttons", "extraButtons", ["NONE", "A", "B", "A_B", "A_B_C"], "Extra mobile buttons.");
    }
}
