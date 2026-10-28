package substates.options;

import states.options.BaseOptionsMenu;

class AudioSubState extends BaseOptionsMenu
{
    public function new()
    {
		heading.text = "Audio";
    	super("Audio");
    }

    override public function buildRows():Void
    {
        rows.push({
            label:"Master Volume",
            field:"volume",
            kind:"volume",
			description:"Master game volume.",
            min:0.0, max:1.0, step:0.1
        });
    }
}
