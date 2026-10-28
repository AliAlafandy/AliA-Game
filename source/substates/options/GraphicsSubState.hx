package substates.options;

import states.options.BaseOptionsMenu;

class GraphicsSubState extends BaseOptionsMenu
{
    public function new()
    {
        title = "Graphics";
        super("Graphics");
    }

    override public function buildRows():Void
    {
        #if desktop
        addBool(
            "Wide screen",
            "wideScreen",
            "Enable wide-screen layout where supported."
        );
        #end

        addBool(
            "Show FPS",
            "showFPS",
            "Show the FPS counter."
        );

        addInt(
            "Framerate",
            "framerate",
            "Target update and draw frame rate.",
            30, 240, 30
        );

        addBool(
            "Antialiasing",
            "antialiasing",
            "Smooth non-pixel graphics."
        );

        addBool(
            "Flashing Lights",
            "flashing",
            "Allow flashing visual effects."
        );

        /*addBool(
        	"VSync",
            "vsync",
            "Enable vertical synchronization where supported."
        );*/

        addString(
            "Theme",
            "themes",
            "Menu theme.",
            ["Normal"] // , "Neon"
        );

        #if desktop
        // Fullscreen
        #end
    }
}
