package substates.options;

import states.options.BaseOptionsMenu;

class ControlsSubState extends BaseOptionsMenu
{
    public function new()
    {
        heading.text = "Controls";
        super("Controls");
    }

    override public function buildRows():Void
    {
        addString(
            "Controls Color",
            "controlsColor",
            "Color theme for mobile controls.",
            ["Yellow", "Blue"]
        );

        /*addInt(
        	"Controls Size",
            "controlsSize",
			"Scale of mobile controls.",
            1, 4, 1
        );*/

        addFloat(
            "Controls Alpha",
            "controlsAlpha",
            "Opacity of mobile controls.",
            0.1, 1.0, 0.1
    	);

        // Edit Controls
    }
}
