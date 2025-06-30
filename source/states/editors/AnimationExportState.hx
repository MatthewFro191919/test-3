package states.editors;

import flixel.FlxState;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Matrix;
import openfl.utils.ByteArray;
import sys.io.File;
import sys.FileSystem;

// IMPORTANT: Import CharacterEditorState using the corrected path:
import states.editors.CharacterEditorState; 

// Also, import the character class (adjust the package as per your project)
// For this example, we'll assume it's in objects.Character:
import objects.Character;

class AnimationExportState extends FlxState
{
    var exportStateZipPath = "AnimationExportState_charpicker_root.zip"; // placeholder
    
    var characterList:Array<String> = [];
    
    override public function create():Void
    {
        super.create();

        var instructions = new FlxText(0, 20, FlxG.width, "Select a character to export", 20);
        instructions.setFormat(null, 20, FlxColor.WHITE, "center");
        add(instructions);

        // Manually build a list of character names from the folder "mods/characters/"
        characterList = [];
        var charDir:String = "mods/characters/";
        if (FileSystem.exists(charDir))
        {
            var files:Array<String> = FileSystem.readDirectory(charDir);
            for (file in files)
            {
                // Expect character JSON files; ignore files with "-dead" in their name.
                if (file.endsWith(".json") && !file.contains("-dead"))
                {
                    var parts = file.split("/");
                    var jsonFile = parts[parts.length - 1];
                    var charName = jsonFile.split(".")[0];
                    characterList.push(charName);
                }
            }
        }
        
        // Create a button for each found character.
        var yPos:Float = 60;
        for (charName in characterList)
        {
            // Create a button with the character's name.
            // The button's callback receives the character name.
            var btn = new FlxButton(50, yPos, charName, function(name:String) {
                exportCharacter(name);
            }, [charName]);
            btn.color = FlxColor.GRAY;
            btn.label.color = FlxColor.WHITE;
            add(btn);
            yPos += 40;
        }
    }

    function exportCharacter(charName:String):Void
    {
        // Instead of loadCharFromFile (which does not exist), create a new character and load its JSON.
        // Adjust the following to use your mod’s method of loading a character.
        var tempChar = new Character(0, 0);
        // Assumes that the character JSON file is located at "mods/characters/{charName}.json"
        tempChar.setCharacterFromJson("mods/characters/" + charName + ".json", charName);
        if (tempChar == null)
        {
            trace("❌ Failed to load character: " + charName);
            return;
        }

        // Set the base export path at the root of the game (where the EXE is located)
        var basePath:String = "exported_frames/";
        if (!FileSystem.exists(basePath))
            FileSystem.createDirectory(basePath);

        // Export each animation’s frames.
        // Use the public API to get the list of animation names.
        var animNames:Array<String> = cast tempChar.animation.getNameList();
        for (anim in animNames)
        {
            var animObj = tempChar.animation.getByName(anim);
            var totalFrames:Int = animObj.numFrames;

            for (i in 0...totalFrames)
            {
                tempChar.playAnim(anim, true);
                tempChar.animation.curAnim.curFrame = i;
                tempChar.updateHitbox();

                // Create a BitmapData of the character's dimensions.
                var bmp:BitmapData = new BitmapData(Math.ceil(tempChar.width), Math.ceil(tempChar.height), true, 0x00000000);
                var mtx:Matrix = new Matrix();
                mtx.translate(-tempChar.offset.x, -tempChar.offset.y);

                try {
                    bmp.draw(tempChar.pixels, mtx);
                } catch (e:Dynamic) {
                    trace("⚠️ draw() failed for frame " + i + " of " + anim + ": " + e);
                    continue;
                }

                var exportPath:String = basePath + charName + "/" + anim + "/";
                if (!FileSystem.exists(exportPath))
                    FileSystem.createDirectory(exportPath);

                var filePath:String = exportPath + "frame" + i + ".png";
                try {
                    var png:ByteArray = bmp.encode(bmp.rect, new PNGEncoderOptions());
                    File.saveBytes(filePath, png);
                    trace("✅ Saved " + filePath);
                }
                catch (e:Dynamic) {
                    trace("⚠️ Failed to export frame " + i + " of " + anim + " for " + charName + ": " + e);
                }
            }
        }
    }
}
