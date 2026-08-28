package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.frames.FlxFramesCollection;
import lime.system.System as LimeSystem;

import lime.app.Application;

import states.menus.SelectState;
import states.menus.OnlineState;
import states.options.OptionsState;

#if MODS_ALLOWED
import states.menus.ModsState;
#end

#if DISCORD_ALLOWED
import data.debug.DiscordRPC;
#end

class MenuState extends GameState
{
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var selectedSomethin:Bool = false;

	var optionShit:Array<String> = [
		'play',
		'online',

		#if MODS_ALLOWED
		'mods',
		#end

		'options',
		'exit'
	];

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

	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		Mods.loadTopMod();
		#end

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/Menus/background'));
		add(bg);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var baseX:Float = 15;
			var baseY:Float = 15;
			
			var menuItem:FlxSprite = new FlxSprite(baseX + (i * 125), baseY + (i * 130));
			menuItem.loadGraphic(Paths.image('menus/Menus/' + optionShit[i] + '_button'));
			menuItems.add(menuItem);

			var scr:Float = (optionShit.length - 4) * 0.9;
			if (optionShit.length < 6)
				scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.updateHitbox();
		}

		/*var version:FlxText = new FlxText(12, FlxG.height - 24, 0, 'Ali Alafandy Game v' + Application.current.meta.get('version'), 12);
		version.scrollFactor.set();
		version.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(version);*/

		changeItem();

		super.create();

		// TODO: plugar seu próprio sistema de touch controls aqui (mobile.controls.*)
		#if mobile
		addCustomDPad();
		addCustomDPadCam();
		#end
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.music('menus/menu'));

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancel'));
				FlxG.switchState(new states.TitleState());
			}

			if (controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirm'));

				selectedSomethin = true;

				FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, function(flick:FlxFlicker)
				{
					switch (optionShit[curSelected])
					{
						case 'play':
							FlxG.switchState(new SelectState());

						case 'online':
							FlxG.switchState(new OnlineState());

						#if MODS_ALLOWED
						case 'mods':
							FlxG.switchState(new ModsState());
						#end

						case 'options':
							FlxG.switchState(new OptionsState());

						case 'exit':
							LimeSystem.exit(1);
					}
				});

				for (i in 0...menuItems.members.length)
				{
					if (i == curSelected)
						continue;

					FlxTween.tween(menuItems.members[i], {alpha: 0}, 0.4, {
						ease: FlxEase.quadOut,
						onComplete: function(twn:FlxTween)
						{
							menuItems.members[i].kill();
						}
					});
				}
			}
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scroll'));

		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		for (i in 0...menuItems.members.length)
		{
			var item = menuItems.members[i];

			if (i == curSelected)
			{
				item.alpha = 1.0;
				item.scale.set(1.1, 1.1); 
			}
			else
			{
				item.alpha = 0.6;
				item.scale.set(1.0, 1.0);
			}
			
			item.updateHitbox();
		}
	}
}
