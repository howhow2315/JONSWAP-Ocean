# Summary
This is a basic liquid simulation using the JONSWAP ocean spectrum density model inside Roblox Studio written in Lua(u).
This demonstrates multiple simulation modes using SkinnedMeshParts, EditableMeshParts, and EditableImages to simulate wave displacement and caustics.
Its all completely open-sourced so go ham

# Examples

### Skinned Mesh Ocean

![Skinned Mesh Ocean](JONSWAPOceanExample_1.gif)
---
### Skinned Mesh Ocean Close-up

![Skinned Mesh Ocean Close-up](JONSWAPOceanExample_3.gif)
---
### Editable Mesh Ocean

![Editable Mesh Ocean](JONSWAPOceanExample_4.gif)
---
### Upscaled Skinned Mesh Ocean

![Upscaled Skinned Mesh Ocean](JONSWAPOceanExample_5.gif)
---
### Water Caustics Day/Night Cycle

![Water Caustics Day/Night Cycle](JONSWAPOceanExample_6.gif)
---

If you'd like to try it live or open it in studio it's all open-sourced under the MIT liscense. Have at it!
This is the [Roblox Page](https://www.roblox.com/games/103550551055804/JONSWAP-Liquid)

## Information
I had initially structured this as half a personal project as well as a system for a game I intend on making, however after diving as far as I could into it, its difficult to say its properly possible.
While yes this looks great and you can implement LOD systems, theres a boundary between scraping for performant systems and something actually worth the effort. Not shockingly this lands much closer to the "not worth the effort" end of it all.
The ideal would be having most of the texturing coloring and foam mapping done via a PBR or shader of some kind but this was designed for Roblox Studio and it simply doesn't allow that at the moment.

In the making of this I made 

1. Two vital components:

  * [`JONSWAP.lua`](https://github.com/howhow2315/JONSWAP-Ocean/blob/main/JONSWAP.lua) module for creating a jonswap "wave spectrum" and sampler.

  * [`LiquidActor.lua`](https://github.com/howhow2315/JONSWAP-Ocean/blob/main/LiquidActor.lua) module for creating actors to compute and handle the Meshes bones/vertices, and colorMap.

1. Two straight forward utility modules:

  * [`PixelMap.lua`](https://github.com/howhow2315/Luau-Utilities/blob/main/PixelMap.lua) module for image handling.
  
  * [`GradientMap.lua`](https://github.com/howhow2315/Luau-Utilities/blob/main/GradientMap.lua) module for wave height color map interpolation.

*Alongside some other junk*

### What to do from here
If you're like me and still love the idea of all of this after knowing how frankly stupid it is to try and run it in Studio without shaders or real materials then heres where you could start studying where I dont think I will:
* Foam textures are absolutely possible but its gonna require a lot of work from this point. It likely has to be done with EditableImages, any other way would surprise me but you can either have your color map read a texture based off height. Thats completely reasonable just complicated. If you plan on doing this I highly recommend starting from the pretty simple PixelMap module I made. If you dont know how it or EditableImages works, its pretty straight forward and reading the module should give you enough insight on it. Warning though; I'm like 90% sure that EditableImages start from the Top-Left instead of Bottom-Left causing y-axis inversion. I got around it twice in pretty similar ways, just expect something like that to happen as youre working with it. Long explanation short I recommend either 2 textures: 1 color, 1 foam texture definition, or mapping a texture to the color points based off of normalized height ratio

* Foam spray, this is also absolutely possible, and a LOT simpler. It should just be a particle system that goes off based off when waves overlap. These overlap at a certain amplitude so mess with the scale some and see it happen. Acerola goes into good depth on this exact thing regarding Jacobian : Wave relation (based off a Sea of Thieves detailed discussion. Which is also super interesting!!)

* Proper Tiling and fixing potential seams. The way I have it structured, each actor runs independently off RenderStepped. Its straight forward and gets what I need it to done. However I believe due to the potential desync of the updates based off of computation/setting costs it occassionally creates a tear or deformation. All the lazy attempts I made at solving this lapsed after creating and staring at a non-tearing seam with zombie eyes.

* LOD! This is super important. TLDR: There are tons and tons of different level of detail tricks you could ABSOLUTELY do and I've done previously (just not implemented here). Past everything you should do, also consider lowering the active waveCount in the jonswap sampling based off of your LOD system, it'll greatly increase performance.

* Dynamic caustics would be very interesting, from IcyMonster's example I approached it using a transparency based texture and got good results. Caustics get just as complicated mechanically as the water itself, because to make it look natural you have to think in great great depth. For example: How does each light source influence the color at this position? How does the distance between the point its cast and the distruption from the water affect the light level? How should the brightness of the mesh/part the caustics are cast on be totally affected based off water depth? I know its a bit silly to think about this stuff but it GREATLY affects the end product. This is something that *could* be extremely interesting depending on how you approach it yourself!

Stating anymore would be overkill, but please please please, if you want to learn more, discuss, or attempt any of this: reach out! Make a pull request, issue or message me on Discord. Discussion is the best way we can learn and develop theses kinds of systems

## References

Icy-Monster. (2024). Phillips-Ocean. GitHub. https://github.com/Icy-Monster/Phillips-Ocean

Acerola. (2023). I Tried Simulating The Entire Ocean. https://youtu.be/yPfagLeUa7k
