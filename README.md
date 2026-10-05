# Compositor for Windows

**A Windows port of [Compositor](https://github.com/robbietilton/Compositor), the open-source macOS image
editor — not Compositor itself.** Upstream is Swift and AppKit and runs on macOS 26 and later on Apple
Silicon; nothing in this repository is the Mac app. What is here is a C# / .NET 10 / Avalonia build of the
same editor's feature set, which is what makes it run on Windows at all.

If you are looking for Compositor, go to **[robbietilton/Compositor](https://github.com/robbietilton/Compositor)**.

---

## Where this came from, and what is new here

This repository is a **fork of a port**, and the credit for nearly all of the code belongs to other people.
Being precise about that matters more than the code does, so:

| Layer | Who made it | What it is |
|---|---|---|
| **Compositor** | [Wonder Assembly LLC](https://github.com/robbietilton/Compositor) | The original macOS editor, Swift and AppKit. MIT, © 2026. The reference this port follows. |
| **The Windows port** | [**@chenguisen**](https://github.com/chenguisen) | ~46,000 lines of C# across 198 files: `Compositor.Core` (document model, tiled renderer, 24 blend modes, selections, tools, filters, `.comp` reader and writer, undo), `Compositor.Desktop` (the Avalonia window) and `Compositor.Cli`. Taken from [`chenguisen/Compositor` @ `compositor_win`](https://github.com/chenguisen/Compositor/tree/compositor_win), commit [`c51be1e`](https://github.com/chenguisen/Compositor/commit/c51be1e57d699edce857115f43bbca579f18dcd4). **This is the overwhelming majority of this repository.** |
| **The changes below** | This fork | Six changes, described honestly below. |

The port's author describes it as a **finished snapshot rather than a supported build** — it tracks the
macOS **1.3.7** feature set while upstream has moved on, and nobody is actively maintaining it. That is
still true here. This fork does not change that; it fixes a bug, adds an icon, adds drag and drop, and
makes the thing installable.

### What this fork actually changed

**1. A bug fix: guides could not be dragged.** `ToolDefaults.ShowGuides` had no initializer, so it defaulted
to `false`. Guides are therefore hidden on a fresh install — and because `CanvasView.GuidesMovable` requires
`ShowsGuides`, a guide pulled off a ruler arrived invisible *and* impossible to move. Upstream's own
`--clicks` self-check asserts this behaviour, which is how it was found. One line in
`src/Compositor.Core/IO/ToolDefaults.cs`:

```csharp
public bool ShowGuides { get; set; } = true;    // was: no initializer
```

With the fix, the port's complete `--clicks` self-check passes for what appears to be the first time —
guide dragging is early in that check, so its failure had been masking every assertion after it.

**2. An application icon.** The port shipped with the default .NET icon — there was no `.ico`, no
`<ApplicationIcon>`, and no `Window.Icon` anywhere. The icon here is converted from the Mac build's own
asset catalog (`Compositor/Assets.xcassets/AppIcon.appiconset`), so both platforms carry the same mark.
Seven sizes, 16 px to 256 px, wired up twice: `<ApplicationIcon>` stamps the executable, and a
`Window.Icon` set from an embedded `AvaloniaResource` covers the title bar and the taskbar.

**3. Drag and drop.** Dragging a file in from Explorer did nothing — the port had no drag-and-drop code at
all, though the Mac build has a good deal of it (`ImageFileDrop.swift`, `.onDrop` on the content view and
the tab strip). Now a dropped picture becomes a layer **centred where the pointer let go**, the first one
onto an empty editor becomes the project itself, several files import in order, and a drag of something
unreadable is refused with the no-drop cursor rather than accepted and then complained about. Note that
Avalonia 12 replaced `IDataObject` with `IDataTransfer`, so the API here is
`e.DataTransfer.TryGetFiles()` and `DragDrop.AddDropHandler(...)`, not the older `e.Data.GetFiles()`.

**4. An output one thirteenth the size.** A plain `dotnet publish` produced **866 MB**, because the
`runtimes/` folder carried native libraries for Linux, macOS, x86 and arm64 beside the x64 ones, along with
349 MB of `.pdb` files. Naming the runtime (`win-x64`) and dropping the debug symbols on publish brings that
to **64 MB** — the same application, with nothing it reads at run time removed.

**5. An installer.** There was none: the port's README says *"There is no installer and nothing is signed:
`dist-app` is a folder you can run `Compositor.Desktop.exe` from."* `installer/Compositor.iss` builds one
with Inno Setup — Start Menu entry, optional desktop icon, an entry in Apps & features that uninstalls it,
the MIT notice shown during setup and installed alongside, and a check for the .NET 10 Desktop Runtime with
a download link if it is missing.

**6. One assertion in a self-check.** `--window` now prints whether the window accepts dropped files, read
back from `DragDrop.GetAllowDrop`. A picture of the interface cannot show that, and "it compiles" is not the
same as "it is wired up".

### What is still missing

The port's own list, unchanged, and worth reading in full in [`PORT-README.md`](PORT-README.md):

- **Remove Background, Object Selection and Select ▸ Subject are absent** — all three are Apple Vision
  subject masks on the Mac. Adding them means an ONNX segmentation dependency (a model, its licence, its
  size), which the port's author declined to take on. Everything downstream of a selection is complete, so
  the loss is the segmentation step alone.
- **The port tracks macOS 1.3.7**; upstream has released past it. That gap is larger than anything above.
- **Nothing is code-signed.** Windows SmartScreen will warn on the installer until someone signs it.

---

## Building

Requires the **.NET 10 SDK**.

```sh
dotnet build Compositor.slnx
dotnet test  tests/Compositor.Core.Tests/Compositor.Core.Tests.csproj    # 848 tests
```

The port holds itself to **zero warnings**, because a warning has repeatedly been the thing that caught a
name resolving to the wrong member. `dotnet build -warnaserror` is what CI runs.

### Checking the window without a pointer

There is no UI-testing harness behind the window, so the desktop app carries self-checks that build the real
window, drive it, and draw it. Each takes a PNG path, prints what it did, and returns.

```sh
dotnet run --project src/Compositor.Desktop -- --window  out.png   # build the window and draw it
dotnet run --project src/Compositor.Desktop -- --clicks  out.png   # the window driven by a real pointer
dotnet run --project src/Compositor.Desktop -- --tools   out.png   # every tool: rail, menu and options bar agree
dotnet run --project src/Compositor.Desktop -- --camera-raw out.png
dotnet run --project src/Compositor.Desktop -- --shortcuts out.png
dotnet run --project src/Compositor.Desktop -- --dialogs out.png
dotnet run --project src/Compositor.Desktop -- --theme-probe
```

`PORT-README.md` documents the rest, including the differential-render technique used to prove the guides,
the grid and the pixel grid.

### Publishing and packaging

```sh
dotnet publish src/Compositor.Desktop -c Release -o dist-slim    # 64 MB, x64, symbols dropped
"${INNO_SETUP}/ISCC.exe" installer/Compositor.iss                # installer/output/*.exe
```

The `RuntimeIdentifier`, `SelfContained` and symbol-dropping settings live in
`src/Compositor.Desktop/Compositor.Desktop.csproj`, so a plain `dotnet publish` already gives the small
output; no extra flags are needed.

---

## Licence

**MIT**, the same licence as upstream. `LICENSE` is upstream's file, verbatim and unchanged —
© 2026 Wonder Assembly LLC — and it travels with this repository because MIT requires it to.

Two things this repository deliberately does **not** claim:

- **It is not Compositor.** It is a port of it for another platform, and it is described that way
  everywhere here, because MIT grants no rights to the name.
- **The code is not this fork's work.** See the table above: the port is
  [@chenguisen](https://github.com/chenguisen)'s, the original is
  [Wonder Assembly LLC](https://github.com/robbietilton/Compositor)'s, and this fork's contribution is the
  six changes listed. [`CREDITS.md`](CREDITS.md) records this in more detail.

**If you are one of the authors above and would rather this fork did not exist, or would like it folded
into your own repository, open an issue here and it will be taken down or moved — no argument.** The port's
README asks for exactly that conversation, and it is the right one to have.
