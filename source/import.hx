#if !macro
#if DISCORD_ALLOWED
import data.debug.DiscordRPC;
#end

#if ELLAWY_ALLOWED
import ellawy.*;
#end

#if ACHIEVEMENTS_ALLOWED
import data.backend.Achievements;
#end

#if mobile
#if android
import mobile.StorageUtil;
#end

import mobile.TouchUtil;

import mobile.controls.MobileControls;
import mobile.controls.IMobileControls;
import mobile.controls.TouchPad;
import mobile.controls.TouchButton;
import mobile.controls.CustomDPad;

import mobile.data.MobileInputID;
import mobile.data.MobileData;
import mobile.data.MobileInputManager;
#end

#if sys
import data.debug.io.AFile as File;
import data.debug.io.AFileSystem as FileSystem;
#end
  
#if android
import android.content.Context as AndroidContext;
import android.widget.Toast as AndroidToast;
import android.os.Environment as AndroidEnvironment;
import android.Permissions as AndroidPermissions;
import android.Settings as AndroidSettings;
import android.Tools as AndroidTools;
import android.os.Build.VERSION as AndroidVersion;
import android.os.Build.VERSION_CODES as AndroidVersionCode;
import android.os.BatteryManager as AndroidBatteryManager;
#end

#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end

import data.controls.Controls;
import data.controls.InputFormatter;

import data.backend.Paths;
import data.backend.CoolUtil;
import data.objects.CustomFadeTransition;
import data.backend.GameState;
import data.backend.GameSubState;
import data.backend.ClientPrefs;
import data.backend.Mods;

import data.objects.BGSprite;

import states.PlayState;

import flixel.FlxState;
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets.FlxShader;

using StringTools;
#end
