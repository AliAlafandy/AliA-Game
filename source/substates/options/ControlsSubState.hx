package substates.options;

import states.options.BaseOptionsMenu;

class ControlsSubState extends BaseOptionsMenu
{
    public function new() super("Controls");

    override public function buildRows():Void
    {
        addString("Controls Color", "controlsColor", ["Yellow", "Blue"], "Color theme for mobile controls.");
        // addInt("Controls Size", "controlsSize", 1, 4, 1, "Scale of mobile controls.");
        addFloat("Controls Alpha", "controlsAlpha", 0.1, 1.0, 0.1, "Opacity of mobile controls.");
        // Edit Controls
    }
}
