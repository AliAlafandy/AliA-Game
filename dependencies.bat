@echo off
color 0a
cd ..
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib git lime https://github.com/AlafandyPorting/lime-0.7.3 --quiet
haxelib install openfl --quiet
haxelib install flixel --quiet
haxelib install flixel-addons --quiet
haxelib install flixel-tools --quiet
haxelib install flixel-ui --quiet
haxelib git hxcpp https://github.com/AlafandyPorting/hxcpp --quiet
haxelib git hxCodec https://github.com/polybiusproxy/hxCodec --quiet
haxelib git SScript https://github.com/AlafandyPorting/SScript --quiet
haxelib install tjson --quiet
haxelib install hxdiscord_rpc --quiet --skip-dependencies
haxelib git ellawy https://github.com/AliAlafandy/ellawy --quiet --skip-dependencies
haxelib install format --quiet
echo Finished!
pause
