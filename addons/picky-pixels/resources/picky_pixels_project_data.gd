## A PickyPixels project contains all information and necessary data
## for rendering a set of sprites, textures, models, etc. within a single
## viewport. The common link between these assets is that they share a color
## palette (and optional effects). Thus, the purpose of a PickyPixels project
## is to set up and easily use a strict color palette.
class_name PickyPixelsProjectData
extends Resource

## Name of the project. Must be unique.
@export var name: String

## Shader that should be applied to the root viewport where all "picky" nodes
## are children. If a picky node is within a tree where its viewport does
## not have the correct shader, there is an error.
@export var root_shader: ShaderMaterial

## TYPE TODO
## PickySprites managed by this project.
@export var sprites: Array[PickySprite2DData]

## Color palette for this project and which sprites use them.
@export var palette: Array[Color]

## Ramps that should be processed in decoding colors, and which sprites use
## them.
@export var ramps: Array[Array]
