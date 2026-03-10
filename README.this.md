Let’s go deeper into the concepts in this chapter, unpacking **every line and idea**, so you understand not just “what to write” but **why it works and how it maps to the GPU and graphics pipeline**.

---

## 1. File Structure and Shader Organization

**Key idea:** Minecraft shaders require a strict folder layout for the loader (Iris) to find and connect shaders properly. Shaders themselves don’t know where they belong; the loader interprets them.

Example:

```
.minecraft/
└── shaderpacks/
    └── composite-tutorial/
        └── shaders/
            ├── composite.vsh
            └── composite.fsh
```

- `.vsh` = vertex shader, A vertex shader runs once for every vertex in a 3D model.
- `.fsh` = fragment shader, A fragment shader runs once for every pixel (fragment) produced by rasterization
- **Full-screen passes** like this one act on the entire rendered image.
- **G-buffer passes** act only on geometry (blocks, entities, etc.) and store data like normals, depth, color, etc.

> Conceptual depth: The file system is effectively how you “register” GPU programs with the game engine. Without it, the shaders exist but never run.

---

## 2. Vertex Shader (`composite.vsh`)

```glsl
#version 330 compatibility
out vec2 texcoord;

void main() {
  gl_Position = ftransform();
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
```

### Deep Explanation:

1. **Vertex shaders run per vertex**
   - This pass uses a **single quad covering the screen**, so there are only **four vertices**.
   - Each vertex executes `main()` once.

2. **`gl_Position = ftransform();`**
   - Converts a vertex from **model space** → **clip space** → **screen coordinates**.
   - Deprecated in modern OpenGL, but Iris auto-patches it to ensure it works.
   - Conceptually: defines **where on the screen this vertex appears**.

3. **`out vec2 texcoord`**
   - Declares a variable that will be **passed to the fragment shader**.
   - In modern GLSL, `out` is the successor to `varying` from older GLSL versions.
   - Concept: the fragment shader needs to know **which pixel corresponds to this vertex’s position**.

4. **`texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;`**
   - `gl_MultiTexCoord0` is the input UV of the vertex.
   - Multiplied by a texture matrix (usually identity unless transformed).
   - `.xy` = **swizzling**, extracts just the 2D components for UV mapping.
   - Conceptually: UV coordinates tell the fragment shader **how to sample the texture**.

5. **Interpolation**
   - GPU interpolates `texcoord` across the quad.
   - If left vertex UV = 0, right vertex UV = 1 → middle pixel UV = 0.5.
   - This allows smooth gradients or spatial effects across the screen.

---

## 3. Fragment Shader (`composite.fsh`)

```glsl
#version 330 compatibility

uniform sampler2D colortex0;
in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
}
```

### Deep Explanation:

1. **Fragment shaders run per pixel**
   - Each pixel covered by the quad executes `main()`.
   - Fragment shaders determine the **final color output** of each pixel.

2. **`uniform sampler2D colortex0`**
   - Represents a **texture containing the rendered scene** (the output of prior passes).
   - `uniform` means its value is the same for all fragments in this pass.

3. **`layout(location = 0) out vec4 color`**
   - Declares the **output buffer** where the pixel color is written.
   - Matches the render target expected by Iris.

4. **`color = texture(colortex0, texcoord)`**
   - Samples the original pixel from the texture at UV coordinate `texcoord`.
   - Concept: this is the simplest post-processing pass — a **pass-through** that copies the scene.

---

## 4. Grayscale Conversion

```glsl
float grayscale = dot(color.rgb, vec3(1.0/3.0));
color.rgb = vec3(grayscale);
```

### Deep Explanation:

1. **Goal:** Make the image grayscale → R=G=B for every pixel.

2. **Dot product formula**
   - `dot(a, b) = a.r*b.r + a.g*b.g + a.b*b.b`
   - Here: `b = vec3(1/3, 1/3, 1/3)` → averages R, G, B.
   - Result: `grayscale = (R + G + B)/3` → scalar value.

3. **Assigning to RGB**
   - `vec3(grayscale)` → `(grayscale, grayscale, grayscale)`
   - Broadcasts the scalar to all three channels → uniform gray.

4. **Why dot product?**
   - More concise than writing `grayscale = (color.r + color.g + color.b)/3;`
   - Can easily extend to weighted averages for perceptual luminance.

---

## 5. Using UVs for Half-Screen Effects

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

Example:

```
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
