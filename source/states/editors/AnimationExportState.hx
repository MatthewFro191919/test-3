
package states.editors;

import flixel.FlxState;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import backend.Paths;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.FlxSubState;

import flixel.system.FlxAssets;
import flixel.FlxScreenshot;

class AnimationExportState extends FlxState
{
    override public function create():Void
    {
        super.create();

        var label = new FlxText(0, 20, FlxG.width, "Press [1] to export BF, [2] for Dad, [3] for both", 20);
        label.setFormat(null, 20, FlxColor.WHITE, "center");
        add(label);
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ONE)
            exportChar("boyfriend");
        if (FlxG.keys.justPressed.TWO)
            exportChar("dad");
        if (FlxG.keys.justPressed.THREE)
        {
            exportChar("boyfriend");
            exportChar("dad");
        }
    }

    function exportChar(charName:String):Void
    {
        var char = (charName == "boyfriend") ? PlayState.instance.boyfriend : PlayState.instance.dad;
        if (char == null)
        {
            trace('Character not found: ' + charName);
            return;
        }

        var basePath = "mods/images/characters/exported_frames/";
        var label = char.curCharacter;
        for (anim in char.animation._animations.keys())
        {
            var frames = char.animation._animations.get(anim).numFrames;
            for (i in 0...frames)
            {
                char.playAnim(anim, true);
                char.animation.curAnim.curFrame = i;
                var fullPath = basePath + label + "/" + anim + "/";
                sys.FileSystem.createDirectory(fullPath);
                var output = fullPath + "frame" + i + ".png";
                FlxScreenshot.takeScreenshot(output);
                FlxG.log.add("Exported " + output);
            }
        }
    }
}
