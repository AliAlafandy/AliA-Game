There you can put your characters folders.

-----------------------------------------------------------------------------------

How files work on character folder:

✓ Learning by Ali Alafandy ✓

charName/
	# you can change charName.png to anything but you should change charName.xml like png one and edit on charName.json in "image": "anything".
	charName.json
	charName.png
	charName.xml
	
If character has an extra animations:
	• put it on charName.png
	• put it on charName_anim.png # _anim can be your animation name
	# if you make charName_anim.png:
	• edit on charName.json
		{
			"anim": {
				[
					"name": "your animation",
					"image": "charName_anim"
				]
			}
		}