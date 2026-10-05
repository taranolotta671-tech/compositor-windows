# Credits

Compositor for Windows is a fork of a port of someone else's application. This file records who did what,
so that the answer is never ambiguous.

## The original: Compositor (macOS)

- **Author:** Wonder Assembly LLC
- **Repository:** https://github.com/robbietilton/Compositor
- **Licence:** MIT, © 2026 Wonder Assembly LLC
- **What it is:** the macOS image editor — Swift and AppKit, macOS 26 and later, Apple Silicon. Every
  feature in this repository exists because it exists there first, and the macOS `CompositorTests` are the
  behaviour spec the C# port is held to.

## The Windows port

- **Author:** [@chenguisen](https://github.com/chenguisen) (GitHub user 50392441)
- **Repository:** https://github.com/chenguisen/Compositor
- **Branch:** `compositor_win`
- **Commit this fork was taken from:** [`c51be1e`](https://github.com/chenguisen/Compositor/commit/c51be1e57d699edce857115f43bbca579f18dcd4)
  (2026-09-30) — *"The READMEs stop claiming parity, and say who would keep it"*
- **What it is:** the entire C# codebase in this repository — 198 files, roughly 46,000 lines. The document
  model, the tiled renderer, all 24 blend modes, selections, every tool's session rules, the filters and
  adjustments, the `.comp` reader and writer, undo, the Avalonia window, the layers panel, the tool rail,
  the options bar, the CLI, and the 848-test suite. **Almost everything here is this person's work.**

  The author describes the port as a *finished snapshot rather than a supported build*, offered so that it
  might outlive its author stepping away. That description still applies to this fork.

## What this fork changed

Six changes, on top of the commit named above:

1. **Guide dragging fixed** — `ToolDefaults.ShowGuides` gained its missing `= true` initializer, in
   `src/Compositor.Core/IO/ToolDefaults.cs`. Guides were hidden by default, which also made them
   undraggable, because `CanvasView.GuidesMovable` requires `ShowsGuides`. Found by running the port's own
   `--clicks` self-check, which fails on the guide-drag assertion.
2. **Application icon** — `src/Compositor.Desktop/Assets/compositor.ico`, generated from the Mac build's
   asset catalog (`Compositor/Assets.xcassets/AppIcon.appiconset` in the upstream repository), wired into
   the executable through `<ApplicationIcon>` and onto the window through `Window.Icon`.
3. **Drag and drop** — `MainWindow.DraggedOver`, `MainWindow.Dropped`, `MainWindow.ImportablePaths`, and
   `ImportImage` refactored so `ImportPath` can be called with a drop point. Nothing of the sort existed in
   the port; the Mac build has `Compositor/IO/ImageFileDrop.swift` and `.onDrop` on its content view.
4. **Output reduced from 866 MB to 64 MB** — `RuntimeIdentifier` and `SelfContained` set in
   `src/Compositor.Desktop/Compositor.Desktop.csproj`, plus a publish target that drops `.pdb` files.
5. **Installer** — `installer/Compositor.iss`, built with [Inno Setup](https://jrsoftware.org/isinfo.php).
6. **A drag-and-drop assertion** in the `--window` self-check (`src/Compositor.Desktop/Program.cs`).

Nothing else was touched.

## Third-party components

The published application carries, unmodified, the runtime dependencies the port already chose:

| Component | Licence |
|---|---|
| [Avalonia](https://avaloniaui.net/) 12.1.3 | MIT |
| [SkiaSharp](https://github.com/mono/SkiaSharp) 4.152.1 | MIT |
| [Magick.NET](https://github.com/dlemstra/Magick.NET) 14.17.2 | Apache-2.0 |
| [BitMiracle.LibTiff.NET](https://github.com/BitMiracle/libtiff.net) 2.4.660 | BSD-3-Clause |
| [Sdcb.LibRaw](https://github.com/Sdcb/Sdcb.LibRaw) 0.21.1.7 | LGPL-2.1 |
| [Svg.Skia](https://github.com/wieslawsoltes/Svg.Skia) 5.2.3 | MIT |
| [Inno Setup](https://jrsoftware.org/isinfo.php) 6.7.3 (build-time only) | Modified BSD |

Consult each project for the authoritative terms.

## If you are one of the authors

This fork exists because the port was published openly under a licence that permits it, and because the
port's own README invites the conversation about where such a build should live. If you would prefer it
taken down, folded into your repository, or renamed, open an issue here — it will be done.
