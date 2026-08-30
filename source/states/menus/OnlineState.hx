package states.menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;

import online.mods.ModLoader;

import openfl.events.TextEvent;
import openfl.events.KeyboardEvent;

import online.Network;
import online.MultiPlayer;
import online.MultiPlayer.RemotePlayer;
import online.MultiPlayer.ConnectionState;
import online.mods.ModInstaller;
import online.mods.ModInstaller.InstallResult;

enum abstract OnlineTab(Int)
{
	var MODS = 0;
	var MULTIPLAYER = 1;
}

class TextInputField
{
	public var value:String = "";
	public var maxLength:Int = 24;
	public var active:Bool = false;
	public var display:FlxText;
	public var placeholder:String;
	public var onSubmit:String->Void;

	public function new(x:Float, y:Float, width:Int, placeholder:String)
	{
		this.placeholder = placeholder;
		display = new FlxText(x, y, width, "", 16);
		display.setFormat(null, 16, FlxColor.WHITE, CENTER);
		refresh();
	}

	public function focus():Void
	{
		active = true;
		refresh();
	}

	public function unfocus():Void
	{
		active = false;
		refresh();
	}

	public function handleChar(char:String):Void
	{
		if (!active)
			return;

		if (value.length < maxLength && char.charCodeAt(0) >= 32)
		{
			value += char;
			refresh();
		}
	}

	public function handleBackspace():Void
	{
		if (!active || value.length == 0)
			return;

		value = value.substr(0, value.length - 1);
		refresh();
	}

	public function handleEnter():Void
	{
		if (!active)
			return;

		if (onSubmit != null)
			onSubmit(value);
	}

	public function clear():Void
	{
		value = "";
		refresh();
	}

	private function refresh():Void
	{
		var shown = value.length > 0 ? value : placeholder;
		display.text = (active ? "> " : "  ") + shown + (active ? "_" : "");
		display.color = value.length > 0 ? FlxColor.WHITE : FlxColor.GRAY;
	}
}

class OnlineState extends GameState
{
	static inline var ENTRY_HEIGHT:Int = 60;
	static inline var LIST_START_Y:Int = 120;
	static inline var CHAT_LINES_MAX:Int = 8;

	var mods:Array<Dynamic> = [];
	var listGroup:FlxSpriteGroup;
	var statusText:FlxText;

	var scrollY:Float = 0;
	var maxScroll:Float = 0;

	var currentTab:OnlineTab = MODS;
	var tabModsBtn:FlxButton;
	var tabMultiBtn:FlxButton;

	var modsGroup:FlxTypedGroup<FlxSprite>;
	var multiGroup:FlxTypedGroup<FlxSprite>;

	var nameInput:TextInputField;
	var roomInput:TextInputField;
	var chatInput:TextInputField;
	var activeInput:TextInputField;

	var connectionStatusText:FlxText;
	var playerListText:FlxText;
	var chatLogText:FlxText;
	var chatLines:Array<String> = [];

	var connectBtn:FlxButton;
	var joinBtn:FlxButton;
	var disconnectBtn:FlxButton;
	var sendChatBtn:FlxButton;

	#if mobile
	public var manager:MobileInputManager;
	var lastTouchY:Float = 0;
	#end

	public function new():Void
	{
		super();
		#if mobile
		manager = new MobileInputManager();
		#end
	}

	override public function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/background'));
		add(bg);

		if (MultiPlayer.instance == null)
			new MultiPlayer();

		var titleText = new FlxText(0, 20, 0, "ONLINE", 24);
		titleText.screenCenter(FlxAxes.X);
		add(titleText);

		tabModsBtn = new FlxButton(FlxG.width / 2 - 80, 55, "Mods", function() switchTab(MODS));
		tabMultiBtn = new FlxButton(FlxG.width / 2 + 20, 55, "Multiplayer", function() switchTab(MULTIPLAYER));
		add(tabModsBtn);
		add(tabMultiBtn);

		buildModsTab();
		buildMultiplayerTab();
		bindMultiplayerEvents();

		#if mobile
		addCustomDPad('NONE', 'BACK');
		addCustomDPadCam();
		#end

		#if (js || sys)
		openfl.Lib.current.stage.addEventListener(TextEvent.TEXT_INPUT, onTextInput);
		#end

		switchTab(MODS);
	}

	private function buildModsTab():Void
	{
		modsGroup = new FlxTypedGroup<FlxSprite>();
		add(modsGroup);
	
		statusText = new FlxText(0, LIST_START_Y - 30, FlxG.width, "Loading mods...", 16);
		statusText.alignment = CENTER;
		modsGroup.add(statusText);
	
		listGroup = new FlxSpriteGroup();
		modsGroup.add(listGroup);
	
		loadModList();
	}

	private function buildMultiplayerTab():Void
	{
		multiGroup = new FlxTypedGroup<FlxSprite>();
		add(multiGroup);

		connectionStatusText = new FlxText(0, LIST_START_Y - 30, FlxG.width, "Disconnected", 16);
		connectionStatusText.setFormat(null, 16, FlxColor.RED, CENTER);
		multiGroup.add(connectionStatusText);

		var inputWidth = 280;
		var centerX = (FlxG.width - inputWidth) / 2;

		nameInput = new TextInputField(centerX - 5, LIST_START_Y, inputWidth, "Player name");
		nameInput.value = MultiPlayer.instance.localPlayerName;
		multiGroup.add(nameInput.display);

		roomInput = new TextInputField(centerX - 5, LIST_START_Y + 35, inputWidth, "Room code");
		roomInput.onSubmit = function(code) attemptJoinRoom(code);
		multiGroup.add(roomInput.display);

		connectBtn = new FlxButton(FlxG.width / 2 - 130, LIST_START_Y + 75, "Connect", onConnectPressed);
		joinBtn = new FlxButton(FlxG.width / 2 - 40, LIST_START_Y + 75, "Join Room", onJoinPressed);
		disconnectBtn = new FlxButton(FlxG.width / 2 + 50, LIST_START_Y + 75, "Disconnect", onDisconnectPressed);
		multiGroup.add(connectBtn);
		multiGroup.add(joinBtn);
		multiGroup.add(disconnectBtn);

		playerListText = new FlxText(0, LIST_START_Y + 115, FlxG.width, "", 14);
		playerListText.setFormat(null, 14, FlxColor.WHITE, CENTER);
		multiGroup.add(playerListText);

		chatLogText = new FlxText(0, LIST_START_Y + 175, FlxG.width, "", 13);
		chatLogText.setFormat(null, 13, FlxColor.LIME, CENTER);
		multiGroup.add(chatLogText);

		chatInput = new TextInputField(centerX - 60, LIST_START_Y + 300, 260, "Type a message...");
		chatInput.onSubmit = function(message) sendChatMessage(message);
		multiGroup.add(chatInput.display);

		sendChatBtn = new FlxButton(centerX + 210, LIST_START_Y + 300, "Send", function() sendChatMessage(chatInput.value));
		multiGroup.add(sendChatBtn);

		refreshPlayerList();
	}

	private function bindMultiplayerEvents():Void
	{
		MultiPlayer.instance.on("connected", function(_) refreshConnectionStatus());
		MultiPlayer.instance.on("disconnected", function(_) refreshConnectionStatus());
		MultiPlayer.instance.on("connection_lost", function(_) refreshConnectionStatus());
		MultiPlayer.instance.on("reconnect_failed", function(_) refreshConnectionStatus());
		MultiPlayer.instance.on("room_state", function(_) refreshPlayerList());
		MultiPlayer.instance.on("player_joined", function(player:RemotePlayer)
		{
			pushChatLine('* ${player.name} joined');
			refreshPlayerList();
		});
		MultiPlayer.instance.on("player_left", function(player:RemotePlayer)
		{
			pushChatLine('* ${player.name} left');
			refreshPlayerList();
		});
		MultiPlayer.instance.on("chat", function(data:Dynamic)
		{
			pushChatLine('${data.name}: ${data.message}');
		});
		MultiPlayer.instance.on("error", function(data:Dynamic)
		{
			pushChatLine('! Error: ${data.message}');
		});
	}

	private function switchTab(tab:OnlineTab):Void
	{
		currentTab = tab;
		modsGroup.visible = (tab == MODS);
		multiGroup.visible = (tab == MULTIPLAYER);

		tabModsBtn.color = (tab == MODS) ? FlxColor.YELLOW : FlxColor.WHITE;
		tabMultiBtn.color = (tab == MULTIPLAYER) ? FlxColor.YELLOW : FlxColor.WHITE;
	}

	private function loadModList():Void
	{
		Network.fetchJson("https://alia-server.onrender.com/api/mods", onModsLoaded, onModsFailed);
	}

	private function onModsLoaded(data:Dynamic):Void
	{
		mods = data.mods;
		statusText.text = mods.length == 0 ? "No mods available" : "";
		renderList();
	}

	private function onModsFailed(reason:String):Void
	{
		statusText.text = "Failed to load mods list";
	}

	private function renderList():Void
	{
		listGroup.clear();
	
		var y = LIST_START_Y;
		for (mod in mods)
		{
			var nameText = new FlxText(0, y, FlxG.width, mod.name, 16);
			nameText.alignment = CENTER;
			listGroup.add(nameText);
	
			var descText = new FlxText(0, y + 18, FlxG.width, mod.description, 12);
			descText.alignment = CENTER;
			listGroup.add(descText);
	
			var btn = new FlxButton(0, y + 36, "Download", null);
			btn.screenCenter(FlxAxes.X);
			btn.onUp.callback = function() downloadMod(mod.download_url, btn);
			listGroup.add(btn);
	
			y += ENTRY_HEIGHT + 20;
		}
	
		maxScroll = Math.max(0, y - FlxG.height + 140);
		scrollY = 0;
		listGroup.y = 0;
	}

	private function downloadMod(url:String, btn:FlxButton):Void
	{
		#if sys
		btn.onUp.callback = null;
		btn.text = "0%";

		var dir = getModsDirectory();
		var fileName = url.split("/").pop();
		var savePath = dir + "/" + fileName;

		Network.downloadFile(url, savePath,
			function(loaded, total)
			{
				btn.text = total > 0 ? Std.int(loaded / total * 100) + "%" : "...";
			},
			function(path)
			{
				handleInstall(path, btn);
			},
			function(reason)
			{
				btn.text = "Failed";
				btn.onUp.callback = function() downloadMod(url, btn);
			}
		);
		#else
		btn.text = "Unsupported";
		#end
	}

	#if sys
	private function handleInstall(zipPath:String, btn:FlxButton):Void
	{
		var result = ModInstaller.install(zipPath);

		switch (result)
		{
			case Success(meta):
				ModLoader.loadAllMods();
				btn.text = "Installed";

			case AlreadyInstalled(meta):
				btn.text = "Reinstall?";
				btn.onUp.callback = function()
				{
					var overwrite = ModInstaller.install(zipPath, true);
					switch (overwrite)
					{
						case Success(_):
							ModLoader.loadAllMods();
							btn.text = "Installed";
						case _:
							btn.text = "Failed";
					}
				};

			case InvalidZip(reason):
				btn.text = "Invalid ZIP";

			case MissingMeta:
				btn.text = "Missing mod.json";

			case Failed(reason):
				btn.text = "Install failed";
		}
	}

	private function getModsDirectory():String
	{
		return #if mobile StorageUtil.getStorageDirectory() + #end "mods";
	}
	#end

	private function onConnectPressed():Void
	{
		MultiPlayer.instance.connect("127.0.0.1", 7777, nameInput.value.length > 0 ? nameInput.value : "Player");
		refreshConnectionStatus();
	}

	private function onJoinPressed():Void
	{
		attemptJoinRoom(roomInput.value);
	}

	private function attemptJoinRoom(code:String):Void
	{
		if (code.length == 0 || !MultiPlayer.instance.isConnected())
			return;

		MultiPlayer.instance.joinRoom(code);
		pushChatLine('* Joining room $code...');
	}

	private function onDisconnectPressed():Void
	{
		MultiPlayer.instance.disconnect();
		refreshConnectionStatus();
		refreshPlayerList();
	}

	private function sendChatMessage(message:String):Void
	{
		if (message.length == 0 || !MultiPlayer.instance.isConnected())
			return;

		MultiPlayer.instance.sendChat(message);
		pushChatLine('${MultiPlayer.instance.localPlayerName}: $message');
		chatInput.clear();
	}

	private function pushChatLine(line:String):Void
	{
		chatLines.push(line);
		if (chatLines.length > CHAT_LINES_MAX)
			chatLines.shift();

		chatLogText.text = chatLines.join("\n");
	}

	private function refreshConnectionStatus():Void
	{
		var label:String;
		var color:FlxColor;

		switch (MultiPlayer.instance.state)
		{
			case CONNECTED:
				label = 'Connected as ${MultiPlayer.instance.localPlayerName}';
				color = FlxColor.LIME;
			case CONNECTING:
				label = "Connecting...";
				color = FlxColor.YELLOW;
			case RECONNECTING:
				label = "Reconnecting...";
				color = FlxColor.ORANGE;
			case DISCONNECTED:
				label = "Disconnected";
				color = FlxColor.RED;
		}

		connectionStatusText.text = label;
		connectionStatusText.color = color;
	}

	private function refreshPlayerList():Void
	{
		var lines:Array<String> = [];
		lines.push('You: ${MultiPlayer.instance.localPlayerName} (${MultiPlayer.instance.currentPing}ms)');

		for (player in MultiPlayer.instance.getPlayers())
			lines.push('${player.name} (${player.ping}ms)');

		playerListText.text = lines.join("\n");
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		MultiPlayer.instance.update(elapsed);

		if (currentTab == MULTIPLAYER)
			refreshPlayerList();

		if (currentTab == MODS)
		{
			#if mobile
			handleScrollInput();
			#else
			if (FlxG.mouse.wheel != 0)
			{
				scrollY = clampScroll(scrollY - FlxG.mouse.wheel * 20);
				listGroup.y = -scrollY;
			}
			#end
		}

		handleInputFocus();
		handleTextControlKeys();

		if (controls.BACK)
		{
			MultiPlayer.instance.off("connected", null);
			GameState.switchState(new MenuState());
		}
	}

	private function handleInputFocus():Void
	{
		if (currentTab != MULTIPLAYER)
			return;

		if (FlxG.mouse.justPressed)
		{
			if (nameInput.display.overlapsPoint(FlxG.mouse.getPosition()))
				setActiveInput(nameInput);
			else if (roomInput.display.overlapsPoint(FlxG.mouse.getPosition()))
				setActiveInput(roomInput);
			else if (chatInput.display.overlapsPoint(FlxG.mouse.getPosition()))
				setActiveInput(chatInput);
			else
				setActiveInput(null);
		}
	}

	private function setActiveInput(field:TextInputField):Void
	{
		if (activeInput != null)
			activeInput.unfocus();

		activeInput = field;

		if (activeInput != null)
			activeInput.focus();
	}

	private function handleTextControlKeys():Void
	{
		if (activeInput == null)
			return;

		if (FlxG.keys.justPressed.BACKSPACE)
			activeInput.handleBackspace();

		if (FlxG.keys.justPressed.ENTER)
			activeInput.handleEnter();

		if (FlxG.keys.justPressed.ESCAPE)
			setActiveInput(null);
	}

	#if (js || sys)
	private function onTextInput(event:TextEvent):Void
	{
		if (activeInput != null)
			activeInput.handleChar(event.text);
	}
	#end

	#if mobile
	private function handleScrollInput():Void
	{
		var touch = FlxG.touches.getFirst();
		if (touch == null) return;

		if (touch.justPressed)
		{
			lastTouchY = touch.screenY;
		}
		else if (touch.pressed)
		{
			var delta = lastTouchY - touch.screenY;
			scrollY = clampScroll(scrollY + delta);
			listGroup.y = -scrollY;
			lastTouchY = touch.screenY;
		}
	}
	#end

	private function clampScroll(value:Float):Float
	{
		return Math.max(0, Math.min(maxScroll, value));
	}

	override public function destroy():Void
	{
		#if (js || sys)
		openfl.Lib.current.stage.removeEventListener(TextEvent.TEXT_INPUT, onTextInput);
		#end
		super.destroy();
	}
}
