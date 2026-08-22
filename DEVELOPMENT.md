# image_dots — Development

Implementation notes, algorithm details, and build procedure for `image_dots`. For usage/parameters, see [README.md](README.md).

---

## Development Setup

Only needed to open/edit/run the sketch from source — not needed to just run a release build (see [README.md](README.md#getting-a-release)).

1. **Install Processing**: download from https://processing.org/download and install (Java Mode, the default one).
2. **Install ControlP5**: in the Processing IDE, go to `Sketch > Import Library... > Manage Libraries...`, search for **ControlP5**, and click Install. This puts it straight into your sketchbook's `libraries/` folder — no manual download/unzip needed. (Library home page, for reference: http://www.sojamo.de/libraries/controlP5)
3. Open `image_dots.pde` in Processing and press Run.

---

## Principle

The final distribution is generated directly by varying `r` (the minimum distance between two points) based on the brightness of the pixel beneath each candidate:

```
dark area   →  small r  →  close points   →  high density
bright area →  large r  →  sparse points  →  low density
```

The **blue noise** property is maintained at all scales: no clusters, no gaps. The distribution is perceptually uniform at the local density dictated by the image.

---

## r_local Formula

Log-linear mapping (exponential in r):

```
r_local = r_min × contrast ^ (t_norm ^ gamma)
```

- `t_norm` ∈ [0, 1]: normalized pixel brightness after clamping to `[min_value, max_value]`, then optional inversion
- `t_norm = 0` (black) → `r_local = r_min` (high density)
- `t_norm = 1` (white) → `r_local = r_min × contrast` = `r_max` (low density)

This mapping ensures that the same brightness difference multiplies `r` by the same factor across the entire tonal range, regardless of the starting grey level.

---

## Architecture

| File | Role |
|------|------|
| `image_dots.pde` | Setup, draw loop, HUD |
| `DataGlobal.pde` | `ImageDotsData` — aggregates image, style, dots, shape, sort |
| `DataDots.pde` | Poisson parameters + Dots tab GUI |
| `DataShape.pde` | Rendering parameters + Shape tab GUI |
| `DataGUI.pde` | `MainPanel` — assembles the 6 tabs (Files, Image, Style, Dots, Sort, Shape) |
| `DotsGenerator.pde` | Variable-density Poisson Disk Sampling algorithm |
| `DotsRenderer.pde` | Point rendering (point mode or regular polygon) |
| `DataSort.pde` | Sort parameters + Sort tab GUI |
| `DotsSort.pde` | Hexagonal spiral sort algorithm |
| `DataDebug.pde` | Debug parameters + Debug tab GUI |

---

## Implementation Details

### Spatial Grid

The cell size is `r_min / √2`, which guarantees that a cell contains at most one point.
The inspection radius is `ceil(r_max / cell) + 1` cells in each direction, to cover all potential neighbours even when `r_max >> r_min`.

### Progressive Generation

Generation is performed in 200 ms slices (`start()` + `resume()`), keeping the interface responsive during computation. The HUD displays the point count and computation time in real time.

### Automatic Triggering

The generator restarts automatically whenever an image or dots parameter changes. Once generation completes, the hexagonal spiral sort always runs (no toggle to skip it) before shapes are rebuilt — changing a sort parameter (`hex_size`) re-sorts without regenerating points. Style and shape parameters are applied without recomputation.

### Hexagonal Spiral Sort

The sort reorders points to minimise plotter travel distance, using a two-level strategy:

1. **Cell assignment** — each point is mapped to a hexagonal grid cell using axial (pointy-top) coordinates. Cell size is controlled by `hex_size`.
2. **Spiral traversal** — cells are visited in a ring-by-ring spiral from the centre cell outward (ring 0, then ring 1 with 6 cells, ring 2 with 12, etc.).
3. **Local nearest-neighbour** — within each cell, points are ordered by nearest-neighbour starting from the last point of the previous cell, ensuring smooth inter-cell transitions.

The result is a globally coherent spiral order with locally optimised segments. Smaller `hex_size` values approach a full nearest-neighbour sort; larger values make the spiral structure more pronounced.

**Visualisation toggles (Sort tab):**
- *Draw path* — draws the full point sequence with a rainbow gradient (red = start, violet = end)
- *Draw hex transitions* — draws each hexagonal cell outline (rainbow-coloured) and the yellow centre-to-centre lines showing the spiral traversal order

### Debug Tab

Diagnostic-only controls to observe `DotsGenerator`'s propagation without changing the final result (the same point cloud is produced no matter how it's watched):

- *Pause* — stops calling `resume()` altogether; generation stays frozen mid-way.
- *Slow Mode* + *Steps / Frame* — caps `resume()` to a small number of active-point attempts per call instead of the usual `MAX_MILLIS` time budget, so propagation advances visibly frame by frame.
- *Show Active* + *Active Color* — draws the current `_active` list (points still eligible to spawn neighbours) over the normal point cloud, via `DotsGenerator.drawActive(color)`, in the swatch colour picked from *Active Color*. Uses the same `ColorGroup`/`ColorRef` swatch picker as the Style tab's Line/Background colours — not ControlP5's `ColorPicker` widget (`GUIPanel.addColorPicker`, bound via `cp5.addColorPicker(object, field)`): that reflection-based binding never actually writes back into the target field, so the picker moved visually but the drawn colour stayed stuck at its default. Untested/unused elsewhere in this codebase — avoid it for future colour controls.
- *New Seed* — draws a new random `dots.seed` and marks `dots`/`data` changed, restarting generation from scratch (same action as the Dots tab's own "New Seed" button, duplicated here for convenience while using the other Debug controls).
- *Clear* — `DotsGenerator.clear()` empties `points`/`_active` and marks `isComplete = true`, without restarting. Sets `_sort_dirty = true` so the (now empty) point list flows through the sort/shape-rebuild pipeline on the next frame, keeping `sorter.sorted`/`shapes_group` in sync instead of showing a stale result. Generation stays empty until *New Seed* (or an image/Dots-tab change) restarts it.

---

## Building a Release

`export_app.ps1` (project root) builds a standalone, installer-free application and packages it as a release zip.

```powershell
.\export_app.ps1
```

This will:
1. Export the sketch as a standalone application via `processing-java --export` (embeds a JRE and all libraries, including ControlP5 — end users install nothing).
2. Copy `Settings/` into the export (the Processing export step does **not** include it, and the sketch crashes on startup without a `Settings/default.json` to load).
3. Zip the result into `releases/image_dots_<variant>_<date>.zip`, ready to hand out.

Useful options:
```powershell
.\export_app.ps1 -ProcessingPath "D:\tools\processing-4.3\processing-java.exe"  # different Processing install
.\export_app.ps1 -Zip $false                                                    # skip the release zip
```

**Note:** the build always targets the OS you run the script on — `-Variant` does not cross-compile for another platform (verified empirically: requesting `linux-amd64` from Windows still produced a Windows build). To produce a macOS or Linux build, run this script on a machine running that OS.
