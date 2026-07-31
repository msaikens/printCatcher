# printCatcher

A Fortran fingerprint capture tool for the DigitalPersona U.are.U 4500 reader
(`VID_05BA&PID_000A`), built as an exercise in binding Fortran directly to C
libraries via `ISO_C_BINDING`.

The project has two paths, both still in the repo:

1. **Active path: the official SDK.** `main.f90` binds directly to
   DigitalPersona's own `dpfpdd.dll` (from the official U.are.U SDK) via
   `bind(C)`. This is what actually captures images today.
2. **Archived path: raw USB from scratch.** `libusb_bindings.f90` +
   `fp4500_device.f90` talk to the reader's raw USB protocol directly via
   libusb, with no SDK or driver dependency beyond WinUSB. This got real
   register-level communication working (power-up, mode registers, interrupt
   handling — all confirmed against hardware) but hit a wall: arming the
   sensor for capture requires an undocumented challenge/response handshake
   that isn't part of any public reverse-engineering effort. See
   [Findings](#findings) below for how that was diagnosed.

## Why Fortran

1. No pointer aliasing by default. In C, the compiler has to assume two pointers might point to overlapping memory unless you add restrict (and even then, compilers are conservative). Fortran's language rules forbid aliasing by default, so the compiler can vectorize/auto-parallelize array math far more aggressively without hand-holding. This is the actual reason Fortran still dominates numerical computing (LAPACK, BLAS, climate models, CFD) — not tradition, but that the compiler can prove more about the code.

2. True native multidimensional arrays. Our fingerprint image is fundamentally a 2D array of pixel intensities. Fortran has real 2D arrays with slicing, whole-array arithmetic (image = image * 2), and reduction intrinsics (sum, maxval) built into the language. In C you're always faking 2D with pointer arithmetic over a flat buffer. For something like a ridge-orientation filter or a Gabor convolution over the image, that's less error-prone and often clearer in Fortran.

3. Interoperability isn't lost. Since we're calling C via bind(C) already, a Fortran matching engine can equally be exposed to C (or C#, or eventually a Node addon) the same way. So going Fortran for the numerical core doesn't trap us — though to be fair, this cuts both ways: C is more universally embeddable (better FFI story into Node/Python/etc.), so this point favors Fortran only mildly, not decisively.

## Status

- [x] SDK path: `dpfpdd_init` → `query_devices` → `open` →
      `get_device_capabilities` → `capture` → PGM output — **confirmed
      working against real hardware** (357x392, 8bpp, quality=GOOD).
- [x] Raw libusb path: device open, interface claim, register read/write,
      interrupt (IRQ) handling, power-up sequence — all confirmed working
      against real hardware.
- [x] Raw libusb path: root-caused why arming didn't work (wrong `bRequest`,
      found via Wireshark comparison against the official SDK's own traffic).
- [ ] Raw libusb path: arm-for-capture blocked on an undocumented
      challenge/response handshake — not pursued further, see Findings.
- [x] Packaged as a real, installable NuGet package (`PrintCatcher`) — see
      [Packaging](#packaging) below.
- [ ] Node.js binding — planned, not started.
- [ ] Other language bindings (Python, etc.) — planned, not started.

## Packaging

This repo's `dpfpdd_bindings.f90` is the shared foundation for two companion
projects (separate repos, both built from the working SDK path above):

- **`printCatcher.Native`** — a thin Fortran-compiled DLL
  (`printcatcher_native.dll`) that wraps the SDK capture flow behind a small,
  stable C API: `pc_init`, `pc_open`, `pc_capture`, `pc_close`, `pc_exit`.
  This is the reusable surface any other language binds against, instead of
  each ecosystem re-implementing the `dpfpdd` struct marshaling itself.
- **`PrintCatcher` (NuGet)** — a C# wrapper (`FingerprintReader`,
  `FingerprintImage`) around `printCatcher.Native` via P/Invoke, packaged
  with both native DLLs (`printcatcher_native.dll` and `dpfpdd.dll`) bundled
  as `win-x64` runtime assets. Verified end-to-end against real hardware
  through an actual `PackageReference` consumption (not just a project
  reference) — a separate console app captured a real fingerprint through
  the packaged library.

One naming gotcha worth knowing if you touch this again: the native DLL is
named `printcatcher_native.dll`, deliberately *not* `printcatcher.dll` —
that name collided case-insensitively with the C# assembly `PrintCatcher.dll`
sitting in the same output folder, and Windows' loader would resolve
`DllImport("printcatcher")` to the wrong file (our own managed assembly,
which of course has no `pc_init` export), producing a confusing
`EntryPointNotFoundException` instead of a `DllNotFoundException`.

**Planned next:** a Node.js binding (likely via FFI — e.g. `koffi` — calling
`printcatcher_native.dll`'s exports directly, no native build toolchain
needed on the consumer's end) and potentially other language bindings
(Python via `ctypes`/`cffi`, etc.), all built the same way: bind against the
native DLL's small C API rather than re-deriving the SDK struct layouts per
language.

## Findings

Worth recording since they took real effort to establish:

- The reader's register protocol (matching libfprint's reverse-engineered
  `uru4000.c` driver for the same USB IDs) uses register addresses/values
  that all check out: `REG_HWSTAT=0x07`, `REG_MODE=0x4e`,
  `MODE_AWAIT_FINGER_ON=0x10`, `MODE_CAPTURE=0x20`, etc.
- However, the actual `bRequest` byte used for register control transfers is
  **`0x0c`**, not the `0x04` that public reverse-engineering notes suggested.
  Discovered by Wireshark-capturing the official SDK sample app's real USB
  traffic (`05ba:000a`) and diffing it against our own.
- Fixing that alone wasn't enough: arming for capture (`MODE_AWAIT_FINGER_ON`)
  requires a preceding handshake at registers `0x33`/`0x34` — write 5 bytes,
  read back 4, repeated with an incrementing byte in the write. The 4-byte
  read values look like genuine pseudorandom output (e.g. `75 b9 4f f4`,
  `c3 f4 9d a9` for two different writes), not a simple echo/counter. This
  doesn't match the AES challenge/response documented elsewhere for other
  devices in this family (different registers, `0x2000`/`0x2010`, 16-byte
  blocks) — it appears to be a separate, undocumented mechanism specific to
  this driver/firmware. This is where the raw-protocol path stopped.

## One-time hardware setup

**For the active SDK path (default):** none needed. The reader should stay
on its normal Windows driver (Device Manager shows it under `Biometric
devices`). Just make sure the official U.are.U SDK is installed (provides
`dpfpdd.dll`).

**Only if experimenting with the archived raw-libusb path:** Windows only
lets libusb talk to a device bound to WinUSB/libusbK/libusb0, so the reader
needs to be temporarily rebound away from its normal driver. This breaks
Windows Hello / official DigitalPersona software for this device until
reverted.

1. Get Zadig: https://zadig.akeo.ie/
2. **Options > List All Devices**
3. Find the entry matching exactly `U.are.U® 4500 Fingerprint Reader`
   (`USB\VID_05BA&PID_000A`). Don't pick anything else in the list.
4. Target driver: **WinUSB** > **Replace Driver**.
5. To revert back to the SDK path: Device Manager > find the reader >
   Uninstall device (check "delete the driver") > unplug/replug to restore
   the original driver.

## Build (Code::Blocks)

1. Open `printCatcher.cbp`.
2. Project's compiler must be a working GNU Fortran install — Toolchain
   executables should point at your actual gfortran, e.g.
   `C:\Strawberry\c\bin\gfortran.exe` (not the default `mingw32-gfortran.exe`,
   which typically doesn't exist).
3. Build. Both `lib/libusb-1.0.dll` and `lib/dpfpdd.dll` must be copied next
   to the built `.exe` (`bin/Debug/` or `bin/Release/`) to run.

`dpfpdd.dll`/`dpfpdd.lib`/`dpfpdd.h` came from the official U.are.U SDK
(`C:\Program Files\DigitalPersona\U.are.U SDK`). The SDK ships an MSVC-format
`.lib` that MinGW's linker can't read directly, so `lib/libdpfpdd.a` was
generated from the DLL itself via `gendef` + `dlltool` (both part of the
MinGW toolchain):

```
gendef dpfpdd.dll
dlltool -d dpfpdd.def --dllname dpfpdd.dll -l libdpfpdd.a
```

## Layout

- `main.f90` — active program: full SDK-based capture flow.
- `dpfpdd_bindings.f90` — `bind(C)` interface to the official SDK
  (`dpfpdd_init`/`query_devices`/`open`/`get_device_capabilities`/`capture`/
  `close`/`exit`), plus derived types mirroring the SDK's C structs.
- `libusb_bindings.f90` / `fp4500_device.f90` — archived raw-libusb path
  (see Status/Findings above). Still compiled into the project but no longer
  called from `main.f90`.
- `include/` — reference copies of `libusb.h` and `dpfpdd.h` (not consumed
  directly by the Fortran build, kept for looking up signatures).
- `lib/` — prebuilt libusb-1.0 MinGW64 binaries (official libusb GitHub
  release v1.0.30) and the official SDK's `dpfpdd.dll` + generated MinGW
  import library.
