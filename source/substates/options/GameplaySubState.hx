package substates.options;

import states.options.BaseOptionsMenu;

class GameplaySubState extends BaseOptionsMenu
{
    public function new() super("Gameplay");

    override public function buildRows():Void
    {
        addBool("Down Scroll", "downScroll", "Place complete bar at the bottom when supported.");
        addBool("Shaders", "shaders", "Enable shaders where supported.");

        #if desktop
        addBool("Discord RPC", "discordRPC", "Enable discord rpc where supported.");
        #end
    }
}
