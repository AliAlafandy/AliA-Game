package substates.options;

import states.options.BaseOptionsMenu;

class GraphicsSubState extends BaseOptionsMenu
{
    public function new() super("Graphics");

    override public function buildRows():Void
    {
                addBool("Show FPS", "showFPS", "Show the FPS counter.");
                addInt("Framerate", "framerate", 30, 240, 30, "Target update and draw frame rate.");
                addBool("Antialiasing", "antialiasing", "Smooth non-pixel graphics.");
                addBool("Flashing lights", "flashing", "Allow flashing visual effects.");
                addBool("Shaders", "shaders", "Enable supported shaders.");
                addBool("VSync", "vsync", "Enable vertical synchronization where supported.");
                addBool("Wide screen", "wideScreen", "Enable wide-screen layout where supported.");
                addString("Theme", "themes", ["Normal", "Dark", "Light"], "Menu theme.");
    }
}
