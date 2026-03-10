# The Programmable Graphics Pipeline 
https://www.youtube.com/watch?v=kpA5X6eI6fM&list=PLvv0ScY6vfd9zlZkIIqGDeG5TUWswkMox&index=4

#### The Graphics Pipeline (Simple Mental Model)

**Core idea:**
The graphics pipeline converts **3D geometry → colored pixels on your 2D screen**.

Think of it as an **assembly line for triangles**.

```
3D vertices → transformations → triangles → pixels → final colors
```

---

### 1. Vertex Specification (CPU → GPU)

**Purpose:** Send geometry data to the GPU.

You define vertices like:

```
(x, y, z)
```

Example:

```
(1.0, 0.0, -5.0)
```

<<<<<<< HEAD
- `.vsh` = vertex shader, A vertex shader runs once for every vertex in a 3D model.
- `.fsh` = fragment shader, A fragment shader runs once for every pixel (fragment) produced by rasterization
- **Full-screen passes** like this one act on the entire rendered image.
- **G-buffer passes** act only on geometry (blocks, entities, etc.) and store data like normals, depth, color, etc.
=======
But vertices usually include **more attributes**:
>>>>>>> bb95c24 (Update "Your first shader")

* position `(x,y,z)`
* texture coordinates `(u,v)`
* normals (for lighting)
* color

Example vertex:

```
struct Vertex {
    vec3 position;
    vec2 texCoord;
    vec3 normal;
};
```

These vertices form **primitives**:

* points
* lines
* triangles (most common)

---

### 2. Vertex Shader

**Runs once per vertex.**

Its main job:

```
Transform vertex position → clip space
```

Typical transformation:

```
gl_Position = Projection * View * Model * vec4(position, 1.0);
```

These matrices do:

| Matrix     | Purpose                     |
| ---------- | --------------------------- |
| Model      | position object in world    |
| View       | position camera             |
| Projection | convert 3D → 2D perspective |

Result: **vertex ends up in clip space**

This is the stage related to the code you asked about earlier.

---

### 3. Tessellation Shader (Optional)

<<<<<<< HEAD
```glsl
if (texcoord.x < 0.5)
    color.rgb = vec3(1, 0, 0); // red left half
else
    color.rgb = vec3(0, 1, 0); // green right half
```

### Deep Explanation:

1. **UV coordinates (`texcoord`)**
   - `texcoord.x` ranges from 0 (left) to 1 (right).
   - `texcoord.y` ranges from 0 (bottom) to 1 (top).

2. **Conditional coloring**
   - Allows **spatial effects** like gradients, splits, or masks.
   - You can create left/right, top/bottom, radial, or circular patterns mathematically.

3. **Concept:** UVs are a normalized abstraction of **screen space**, independent of resolution.

---

Focus on the **goal**: the GPU wants a **new texture coordinate** computed by a **linear transform**.

Your line:

```glsl
texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
```

means:

**“Take the original texture coordinate and transform it with a matrix.”**

---

# 1. Start with the original coordinate

A vertex has a texture coordinate:

```
(u, v)
```
=======
Adds **more geometry automatically**.
>>>>>>> bb95c24 (Update "Your first shader")

Example:

```
<<<<<<< HEAD
(0.3, 0.7)
```

This says **where to sample in the texture image**.

---

# 2. The matrix defines how coordinates change

Example matrix:

```
| 2 0 0 0 |
| 0 2 0 0 |
| 0 0 1 0 |
| 0 0 0 1 |
```

Multiply it with:

```
(u, v, 0, 1)
```

Compute:

```
x' = 2u
y' = 2v
```

So

```
(0.3, 0.7) → (0.6, 1.4)
```

Now the GPU samples the texture at **(0.6, 1.4)** instead of **(0.3, 0.7)**.

If texture wrapping is enabled, this makes the texture **tile**.

So the matrix **moves the lookup position** inside the texture.

---

# 3. Why a matrix is used

Because one matrix can represent many transformations:

| Matrix effect | Result          |
| ------------- | --------------- |
| scale         | texture tiles   |
| translate     | texture scrolls |
| rotate        | texture spins   |
| shear         | texture skews   |

Example scrolling texture:

```
|1 0 0 0.2|
|0 1 0 0  |
|0 0 1 0  |
|0 0 0 1  |
```

This produces:

```
(u,v) → (u + 0.2, v)
```

The texture appears to **slide across the surface**.

---

# 4. Why the vector has 4 components

The GPU needs

```
(u, v, 0, 1)
```

because the matrix is **4×4**.

The **1** allows translation to work:

```
x' = u + offset
```

Without that extra component, the matrix could only **scale or rotate**, not **shift coordinates**.

---

# 5. Why `.xy` is taken

After multiplication you get

```
(x', y', z', w')
```

But textures are **2-dimensional**, so only:

```
(x', y')
```

are used.

---

# The key mental picture

Original lookup:

```
texture(u,v)
```

After the matrix:

```
texture(transformed_u, transformed_v)
```

So the matrix **warps the coordinate system used to read the texture**.

---

If you'd like, I can also show the **one geometric picture that makes matrix transforms instantly intuitive** (why the numbers actually move the point).
=======
1 triangle → subdivided into many triangles
```

Used for:

* terrain
* detailed surfaces
* displacement mapping

Most Minecraft mods **don't use this**.

---

### 4. Geometry Shader (Optional)

Runs **per primitive (triangle/line/point)**.

It can:

* create new geometry
* modify existing geometry

Example uses:

* particle systems
* billboards
* explosions

Minecraft shaders sometimes use this for **particles or grass effects**.

---

### 5. Primitive Assembly

Vertices are grouped into **actual shapes**.

Example:

```
3 vertices → triangle
2 vertices → line
```

At this stage:

* triangles outside the camera are **clipped**
* hidden faces can be **culled**

Example:

Back faces of a cube are removed.

---

### 6. Rasterization

This step converts **triangles → pixels**.

Example:

```
Triangle on screen
↓
Which pixels does it cover?
↓
Generate fragments
```

Fragments are **potential pixels**.

---

### 7. Fragment Shader

Runs **once per fragment (pixel)**.

Its job:

```
Compute the final color
```

Example shader:

```
color = texture(textureSampler, texCoord);
```

This is where:

* textures
* lighting
* transparency
* shadows

are calculated.

---

### 8. Per-Fragment Operations

Final checks before drawing.

Examples:

**Depth test**

```
Which object is closer to the camera?
```

**Stencil test**

Used for:

* mirrors
* outlines
* portals

**Blending**

For transparency:

```
finalColor = blend(newPixel, oldPixel)
```

---

##### Final Result

After all stages:

```
GPU framebuffer → screen pixels
```

You see the final image.

---

### The Whole Pipeline (Condensed)

```
1. Vertex Data (CPU)
2. Vertex Shader
3. Tessellation (optional)
4. Geometry Shader (optional)
5. Primitive Assembly
6. Rasterization
7. Fragment Shader
8. Depth/Blend Tests
9. Final Pixels on Screen
```

---

### The Most Important Parts to Understand (for Minecraft modding)

You mainly need these **three stages**:

##### 1. Vertex Shader

Transforms vertices to **clip space**.

##### 2. Rasterization

Triangles become **fragments**.

##### 3. Fragment Shader

Fragments become **final colored pixels**.

These are used in:

* Minecraft shaders
* particle effects
* custom rendering

---

### How This Relates to Your Question (ftransform)

Old shader code:

```
gl_Position = ftransform();
```

Meaning:

```
Apply ModelViewProjection transform automatically
```

Modern equivalent:

```
gl_Position = Projection * View * Model * vec4(position,1);
```

This is **exactly the vertex shader stage** of the pipeline.

---

✅ **Key takeaway**

The graphics pipeline is simply:

```
3D vertices
   ↓
Vertex Shader (transform)
   ↓
Triangles
   ↓
Rasterization
   ↓
Fragment Shader (color)
   ↓
Pixels on screen
```

---

If you're making **Minecraft mods with custom particle effects**, I can also show you the **3 OpenGL concepts that matter most for Minecraft modding** (it's surprisingly small).




# Clip Space (among others spaces)

Here’s a clear explanation of **clip space** and why it matters in graphics:

---

 1. Where it sits in the graphics pipeline

When a vertex is processed in the GPU, it passes through multiple coordinate spaces:

```
Model space → World space → View space → Clip space → NDC → Screen space
```

* **Model space:** vertex relative to its object
* **World space:** vertex relative to the scene
* **View space (camera space):** vertex relative to the camera
* **Clip space:** after projection, before perspective divide
* **NDC (Normalized Device Coordinates):** clip space divided by `w`, ranges [-1, 1] in X/Y/Z
* **Screen space:** finally mapped to pixels on your screen

---

 2. What clip space actually is

* Clip space is a **4D homogeneous coordinate system**: `(x, y, z, w)`
* After multiplying by the **ModelViewProjection matrix**, a vertex is in clip space
* The **GPU uses clip space to determine which vertices are inside the view frustum**
* Vertices outside the frustum are “clipped” (discarded)

---

 3. Why 4 components `(x, y, z, w)`?

* Allows **perspective projection** via homogeneous division:

```glsl
vec3 ndc = vec3(x/w, y/w, z/w);  // divide by w
```

* After dividing by `w`, you get **Normalized Device Coordinates (NDC)** ranging from -1 to 1
* This makes mapping to screen coordinates easy

---

 4. Quick example

Suppose a vertex at `(1, 1, 1)` in camera space. After projection:

```glsl
gl_Position = ProjectionMatrix * ViewMatrix * ModelMatrix * vec4(1,1,1,1);
```

* Result: `(2, 3, -5, 4)` in clip space
* Divide by `w = 4` → NDC `(0.5, 0.75, -1.25)`
* Coordinates outside [-1,1] are **clipped**, the rest mapped to pixels

---

 5. TL;DR

**Clip space is the GPU’s “evaluation space” where it decides which vertices/polygons are visible**.

* It’s **4D**, because homogeneous coordinates allow translation, rotation, scaling, and perspective in one matrix
* After division by `w`, vertices go to **Normalized Device Coordinates** and finally to the screen

---

If you want, I can make a **tiny visual diagram showing all the spaces** from Model → Clip → Screen, which makes this concept instantly clear. It’s the easiest way to understand `ftransform()` and `gl_Position`.

# Model, View, Projection (Matrix operations)
https://www.youtube.com/watch?v=-tonZsbHty8
#### Goal of Model–View–Projection (MVP)

**Purpose:** Convert a **3D point in a model → 2D point on the screen**.

This happens using **three matrix transformations** applied in order:

```
Model → View → Projection
```

Or more explicitly:

```
Model Space → World Space → Camera Space → Clip Space
```

Each step is a **matrix multiplication on the vertex**.

---

### 1. Model Matrix (Model → World)

**Purpose:** Place an object inside the world.

Objects are usually created around `(0,0,0)` in **model space**.

The model matrix applies three operations:

1. **Scale**
2. **Rotate**
3. **Translate**

Example vertex in model space:

```
v = (1, 1, 1)
```

Apply model matrix:

```
worldPos = Model * vec4(v,1)
```

Now the vertex is positioned somewhere in the **world**.

#### Example

Object originally centered at origin:

```
(0,0,0)
```

Translate by `(5,0,0)`:

```
world position → (5,0,0)
```

Every object has **its own model matrix**.

Example in a game:

| Object | Model Matrix            |
| ------ | ----------------------- |
| Tree   | move to forest location |
| Player | move to player position |
| House  | move to map location    |

---

### 2. View Matrix (World → Camera)

**Purpose:** Transform the world relative to the **camera**.

Instead of moving the camera, graphics engines usually **move the world opposite to the camera movement**.

If the camera moves forward:

```
world moves backward
```

Mathematically:

```
viewPos = View * worldPos
```

The result is **camera space coordinates**.

##### Example

Camera position:

```
camera = (0, 0, 5)
```

Object position:

```
(0,0,0)
```

After view transform:

```
(0,0,-5)
```

Meaning:

```
object is 5 units in front of camera
```

---

### 3. Projection Matrix (Camera → Clip Space)

**Purpose:** Convert **3D coordinates → perspective projection**.

This creates the effect:

```
far objects → smaller
near objects → larger
```

Example real-world analogy:

* Railroad tracks appear to meet at the horizon
* Distant objects shrink toward a **vanishing point**

Projection matrix performs:

```
clipPos = Projection * viewPos
```

Result:

```
(x, y, z, w)
```

This is **clip space**.

---

### 4. Perspective Divide

Next the GPU divides by `w`.

```
x = x / w
y = y / w
z = z / w
```

This creates **Normalized Device Coordinates (NDC)**:

```
range: -1 → 1
```

Then GPU maps this to screen pixels.

---

### Complete MVP Transformation

All three matrices combine into one multiplication:

```
gl_Position = Projection * View * Model * vec4(position,1);
```

Order matters:

```
1. Model transform
2. View transform
3. Projection transform
```

Applied **right to left**.

---
## Visual Flow

```
Model Space
   ↓ (Model Matrix)
World Space
   ↓ (View Matrix)
Camera Space
   ↓ (Projection Matrix)
Clip Space
   ↓ (Perspective divide)
NDC
   ↓
Screen Pixels
```

---

### Example Vertex Journey

Start vertex:

```
(1,1,1)
```

After Model transform:

```
(6,1,1)   ← object moved in world
```

After View transform:

```
(6,1,-4)  ← camera space
```

After Projection:

```
clip space coordinates
```

After divide:

```
screen position
```

---

### Why the Matrix is 4×4

Matrices are **4×4** because we use **homogeneous coordinates**.

Vertex format:

```
(x,y,z,w)
```

This allows:

* translation
* rotation
* scaling
* perspective projection

to all be represented with **matrix multiplication**.

---

### Why This Matters for Minecraft Mods

If you're writing custom shaders:

You will see code like:

```
gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1);
```

Meaning:

```
vertex
 → model transform
 → camera transform
 → perspective transform
 → screen
```

---

### The 3 Things You Really Need to Remember

##### 1. Model Matrix

Moves **object into the world**

##### 2. View Matrix

Moves **world relative to camera**

##### 3. Projection Matrix

Creates **perspective (3D → 2D)**

---

✅ **One-line summary**

```
ScreenPosition = Projection × View × Model × Vertex
```

---

If you're doing **Minecraft particle effects**, I can also explain the **exact part of MVP Minecraft shaders modify** (it's much simpler than full OpenGL).

# gl_Position in GLSL
gl_Position — contains the position of the current vertex

# Homogeneous coordinates (why we use vec4)

## Goal of Homogeneous Coordinates

Homogeneous coordinates allow **translation, rotation, scaling, and projection** to all be done with **matrix multiplication**.

Without them, **translation would not work with matrices**.

This is why graphics uses **4D vectors for 3D positions**.

---

### 1. The Problem (Normal Coordinates)

A normal 3D vertex:

```id="d1h7qf"
(x, y, z)
```

Example:

```id="s0efnv"
(2, 3, 4)
```

Matrix multiplication can easily do:

* rotation
* scaling

Example scale matrix:

```id="y6qb3c"
[2 0 0]
[0 2 0]
[0 0 2]
```

Multiply:

```id="akbfli"
(2,3,4) → (4,6,8)
```

But **translation cannot be done with a 3×3 matrix**.

Example translation:

```id="6djfok"
(2,3,4) + (5,0,0)
```

Result:

```id="cjsu3j"
(7,3,4)
```

This is **addition**, not matrix multiplication.

Graphics pipelines need **one unified operation**.

---

### 2. Solution: Add One More Dimension

We extend the vector:

```id="1aqrjo"
(x, y, z) → (x, y, z, w)
```

This is a **homogeneous coordinate**.

Typical vertex:

```id="52z5fo"
(2, 3, 4, 1)
```

Now we can use **4×4 matrices**.

---

### 3. Translation Using Homogeneous Coordinates

Translation matrix:

```id="q8m5y2"
[1 0 0 tx]
[0 1 0 ty]
[0 0 1 tz]
[0 0 0 1 ]
```

Multiply:

```id="rbuv3n"
(2,3,4,1)
```

Result:

```id="o76pzt"
(2+tx, 3+ty, 4+tz, 1)
```

Example translation `(5,0,0)`:

```id="u1xxfl"
(2,3,4,1) → (7,3,4,1)
```

Translation now works with **matrix multiplication**.

---

##### 4. What the W Value Means

The fourth component `w` controls **how coordinates behave**.

##### For positions

```id="c0pdfl"
(x, y, z, 1)
```

These are **actual points in space**.

---

##### For directions

```id="dc18ip"
(x, y, z, 0)
```

These represent **vectors** (no position).

Example:

* light direction
* surface normal
* velocity

---

##### Why `w = 0` matters

Translation should not affect directions.

Example:

```id="o6tx6c"
translate (5,0,0)
```

Direction vector:

```id="5e8h0f"
(1,0,0,0)
```

Result remains:

```id="v6l4m5"
(1,0,0,0)
```

So directions stay unchanged.

---

### 5. Perspective Projection Trick

After projection we get:

```id="u1fcif"
(x, y, z, w)
```

To convert to screen coordinates:

```id="6khk6h"
(x/w, y/w, z/w)
```

This is called the **perspective divide**.

It creates the effect:

```id="z2aq1s"
far objects → smaller
near objects → larger
```

Example:

Before divide:

```id="1uhq1t"
(10, 5, 2, 2)
```

After divide:

```id="t6f3ab"
(5, 2.5, 1)
```

---

### 6. Why Homogeneous Coordinates Are Essential

They allow **all transformations to be represented as matrices**:

| Transformation         | Matrix |
| ---------------------- | ------ |
| Scale                  | ✔      |
| Rotation               | ✔      |
| Translation            | ✔      |
| Perspective projection | ✔      |

Without homogeneous coordinates:

```id="8l7rv6"
translation would require special handling
```

With them:

```id="1x45za"
everything = matrix multiplication
```

---

### 7. In the Graphics Pipeline

Vertices start like this:

```id="hq3s7o"
vec4(position, 1.0)
```

Example shader code:

```id="lffmcc"
gl_Position = Projection * View * Model * vec4(position,1);
```

This produces a **clip-space homogeneous coordinate**.

Then GPU performs:

```id="qcs9sw"
x = x / w
y = y / w
z = z / w
```

This gives **normalized device coordinates**.

---

### 8. Visual Intuition

Normal coordinate:

```id="02f29h"
(x,y,z)
```

Homogeneous coordinate:

```id="qfjnp4"
(x,y,z,w)
```

Final 3D point:

```id="3gm4tm"
(x/w, y/w, z/w)
```

---

### The One Sentence to Remember

Homogeneous coordinates let graphics systems perform **translation, rotation, scaling, and perspective using one unified matrix pipeline**.

---

If you'd like, I can also show a **very simple geometric interpretation of homogeneous coordinates (why points with different w represent the same position)** that makes the concept click instantly.

# Texture Coordinate

Texture coordinates are values that map a texture to a 3D object, typically ranging from 0 to 1 in the u (horizontal) and v (vertical) directions. They specify which part of a texture image should be applied to each vertex of the object.

## Short Answer

We transform the original texture coordinates to **modify how the texture appears without changing the model’s UVs**.

The model keeps simple UVs.
The **matrix changes them at render time**.

---

# The Idea

Original UVs:

```
vertex → (u, v)
```

But sometimes we want effects like:

* scrolling textures
* rotating textures
* repeating textures
* selecting part of a texture atlas

Instead of **editing the mesh**, we transform the UVs with a matrix.

---

# Example 1 — Scrolling Water

Original UV:

```
(0.3, 0.7)
```

Water animation:

```
(u, v + time)
```

Result:

```
(0.3, 0.7 + time)
```

The texture **moves upward**.

This is done by a **translation matrix**.

---

# Example 2 — Texture Tiling

Original UV:

```
(0.4, 0.6)
```

Scale matrix:

```
(u*4, v*4)
```

Result:

```
(1.6, 2.4)
```

Texture repeats **4× across the surface**.

---

# Example 3 — Texture Atlas

Minecraft packs many textures into **one big image**.

Original UV:

```
(0 → 1)
```

Matrix shifts them into the correct tile:

```
(u * tileSize + offset)
```

Example result:

```
(0.42, 0.18)
```

Now the mesh samples the **correct block texture**.

---

# Example 4 — Rotating Textures

For things like:

* portals
* magical effects
* animated particles

Matrix rotates UVs:

```
(u,v) → rotated(u,v)
```

The texture spins **without rotating the geometry**.

---

# Why This Is Powerful

Without transformation you would need to:

* modify the mesh
* re-upload vertex data
* duplicate models

Instead the GPU just applies:

```
matrix × coordinate
```

This is **very cheap and very flexible**.

---

# Key Idea to Remember

The mesh stores **base UVs**.

The shader transforms them to produce **final UVs**.

```
base UV
   ↓
texture matrix
   ↓
final UV
   ↓
texture lookup
```

---

### One Sentence Summary

We transform original texture coordinates so we can **animate, scale, shift, or rotate textures dynamically without modifying the model**.

---
# Texture Coordinates Vs. UV Coordinates

Take the vertex texture coordinates, transform them with the texture matrix, and store the resulting UV coordinates.

Texture coordinates are values that map a texture to a 3D object, typically ranging from 0 to 1 in the u (horizontal) and v (vertical) directions. They specify which part of a texture image should be applied to each vertex of the object.

1. gl_MultiTexCoord0

What it is:
The original texture coordinates of the vertex.

2. gl_TextureMatrix[0]

What it is:

A 4×4 matrix that transforms texture coordinates.

`gl_TextureMatrix[0] * gl_MultiTexCoord0`

This is matrix × vector multiplication.

mat4 * vec4 → vec4

Meaning:

take the UV coordinates
apply the texture transformation

Example:

Input UV:

(0.5, 0.5)

After scaling matrix:

(1.0, 1.0)

Texture now repeats.

So this step:

transforms the texture coordinates
>>>>>>> bb95c24 (Update "Your first shader")
