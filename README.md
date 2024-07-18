![GIF of three sprites--an apple, a carrot, and a bouquet of herbs--being partially lit by three moving lights.](images/hero_demo.gif)

# PickyPixels

Pixel-perfect control over colors and lighting in the [Godot Engine]("https://godotengine.org/")
(version 4.2 or later).

This plugin is used for game devs who want to make a game using a pixel art with a strict color
palette, and who want to control how sprites behave based on lighting. With PickyPixels, you can
create different versions of a sprite based on how "well-lit" it is, create a texture within
the plugin's UI, and it will handle the rest for you.

**Disclaimer: This plugin is in its early stages! There may be bugs or breaking changes**
**with future versions.**

## Current Features

- Configurable lighting behavior for 2D textures.
- Simple texture library and editor.
- Easy-access color palette.

## Future Features

- 3D Support.
- Effects such as dithering and outlining.
- Updating color palettes for all textures at once.
- Multiple color palettes.
- Texture "variations" that can be swapped in real time.
- Ease-of-use updates based on new Godot features.

# Getting Started

- [Installation](#installation)
- [Setting up](#setting-up)
- [Creating textures](#creating-textures)
- [Using textures](#using-textures)

## Installation

**This plugin was written in Godot v4.2, so it may not work with earlier versions!**

1. Download the zip from the latest release on the
[releases](https://github.com/auranym/picky-pixels/releases) page.
2. Within your project, extract the `picky-pixels` folder into your `addons` folder.
  If your project does not have an `addons` folder, create one first.
  This will create a new folder called `picky_pixels` within your project's root.
  You may also see some errors in the console, but they can be ignored. At this point,
  your project should look something like this:
  ![Screenshot of a Godot engine project setup after the PickyPixels plugin has been added to the addons folder. There are three folders. One is called addons, another is called picky-pixels and is within the addons folder, and lastly is a folder at the root level called picky_pixels.](images/project_root.png)
  
3. **Restart Godot.** Then, enable the plugin by going to **Project->Project** Settings,
  in the **Plugins** tab. You should now see a new editor tab called PickyPixels.
  ![Screenshot of Godot engine editor tabs, with a new underlined tab called PickyPixels on the far right](images/editor_tabs.png)

You are now ready to start using PickyPixels!

![Screenshot of the PickyPixels library after the plugin has been enabled](images/empty_library.png)

## Setting up

Due to some missing features within Godot related to low-level rendering (such as
[shader templates](https://github.com/godotengine/godot-proposals/issues/8366)),
PickyPixels requires some extra setup to work correctly.

### Color palette

First, your game must have a color palette in the form of a PNG file. This file does not have to
look like anything in particular, but it must have *every color within your color palette*.
I recommend keeping this file within your game's project files, but it does not have to be.

Once you have your color palette PNG file handy, load it into PickyPixels by clicking the
"Load palette" button:

![Screenshot of the PickyPixels editor overlayed by a window titled "Open a File". Within this window, a file called palette.png is selected.](images/palette_selected.png)

Clicking "Open" will cause the colors within your color palette PNG to be loaded into the plugin:

![Screenshot of the PickyPixels color palette section. There are 24 colors, numbered 0 through 23](images/color_palette.png)

### Main shader material

Next, every texture created within PickyPixels must be within a
[SubViewportContainer](https://docs.godotengine.org/en/stable/classes/class_subviewportcontainer.html)
with the main shader material attached to it. If you are making a game with pixel art graphics,
you are likely to be using a SubViewportContainer anyway.

To add this main shader material to the SubViewportContainer, drag and drop the "Main Material"
item within the library to the material property of the SubViewportContainer.

![GIF showing the action of dragging the Main Material item from the PickyPixels library onto the material property of a SubViewportContainer](images/adding_main_material.gif)

Now your project and game is setup for PickyPixels textures!

## Creating textures

Currently, PickyPixels supports creating special
[Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html)
resources to be used throughout your game wherever you would use a texture.

To create a new texture within the plugin with special lighting behavior, follow these
steps:

1. Create versions of your base texture based on how well-lit that texture should be (up to 16).
  You can make these with whatever program you'd like, but each texture should be saved as
  PNG files. Add these PNG files anywhere in your project.
  For this example, we will be setting up the apple texture seen at the top:
  ![Image of four identical pixel-art apples, each within progressively brighter lighting](images/apple_variations.png)

2. Click on the "new" icon within the PickyPixels library to create a new texture. This will
  create a new texture. You can right click to see options or double-click to open the editor.
  For this example, we'll rename the new texture item to "apple" and then open the editor:
  ![GIF of a series of actions within the PickyPixels library. First, the "new texture" button is clicked, creating a new texture called new_item. Next, this new item is right-clicked, revealing a menu of 3 options: edit, rename, and delete. Rename is selected, and the item is renamed to "apple". Lastly, the item is right-clicked again and "edit" is selected, changing the screen to the PickyPixels editor.](images/new_texture.gif)

3. This brings us to the editor. Within this editor we can configure how many "light levels" this
  texture has, which is just how many variations that this texture has based on how well-lit it is.
  To change the number of light levels, modify the number in the top-right of the editor.
  For our example, we are using four light levels:
  ![GIF of a series of actions within the PickyPixels editor. The mouse cursor moves to a section for number input labeled "light levels". The initial value is 1. The cursor clicks on a button to increase the number three times, bringing the new value of the number to 4.](images/set_light_levels.gif)

4. Next, drag and drop each texture variation to its corresponding light level. Texture variations
  for less light should be for light levels with smaller numbers.
  ![GIF of a series of four actions within the PickyPixels editor. Each one involves dragging and dropping an image from the file explorer to the editor's display area. Once the file is dropped, the image can be seen within the editor. This done four times, and in between, a new light level tab is selected, so that a new file can be drag-and-dropped into the editor for that light level](images/set_textures.gif)
  Alternatively, you can drag and drop multiple texture variants at once, and they will be loaded
  in based on alphanumerical order.
  ![GIF of a serious of actions within the PickyPixels editor. First, four PNG files are selected within the file explorer. Next, they are drag-and-dropped into the editor's main display area. Once released, the first image is displayed. The four light levels are clicked on, showing a new image each time, indicating that dragging and dropping multiple files configures multiple light levels](images/set_textures_bulk.gif)


## Using textures

<style>
img {
  display: block;
  margin-top: 12px;
  margin-bottom: 12px;
}
</style>