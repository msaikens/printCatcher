# printCatcher

Raw USB communication with a DigitalPersona U.are.U 4500 fingerprint reader
(`VID_05BA&PID_000A`), written in Fortran via `ISO_C_BINDING` calling directly
into libusb-1.0's C API. No official DigitalPersona SDK, no libfprint
dependency — the protocol is an original implementation informed by the
publicly documented, reverse-engineered protocol from the LGPL `libfprint`
project's `uru4000.c` driver.

## Why Fortran

1. No pointer aliasing by default. In C, the compiler has to assume two pointers might point to overlapping memory unless you add restrict (and even then, compilers are conservative). Fortran's language rules forbid aliasing by default, so the compiler can vectorize/auto-parallelize array math far more aggressively without hand-holding. This is the actual reason Fortran still dominates numerical computing (LAPACK, BLAS, climate models, CFD) — not tradition, but that the compiler can prove more about the code.

2. True native multidimensional arrays. Our fingerprint image is fundamentally a 2D array of pixel intensities. Fortran has real 2D arrays with slicing, whole-array arithmetic (image = image * 2), and reduction intrinsics (sum, maxval) built into the language. In C you're always faking 2D with pointer arithmetic over a flat buffer. For something like a ridge-orientation filter or a Gabor convolution over the image, that's less error-prone and often clearer in Fortran.

3. Interoperability isn't lost. Since we're calling C via bind(C) already, a Fortran matching engine can equally be exposed to C (or C#, or eventually a Node addon) the same way. So going Fortran for the numerical core doesn't trap us — though to be fair, this cuts both ways: C is more universally embeddable (better FFI story into Node/Python/etc.), so this point favors Fortran only mildly, not decisively.

## Status

- [x] libusb bindings for init/exit, open/close, claim/release interface,
      control_transfer, bulk_transfer
- [x] Device open + interface claim confirmed working against real hardware
- [ ] Register read/write helpers (control transfer wrappers)
- [ ] Device init sequence (power-up, encryption-disable patch)
- [ ] Arm-for-capture / finger-detect / bulk image read
- [ ] Raw image output

## One-time hardware setup: rebind the reader to WinUSB

Windows only lets libusb talk to a device bound to WinUSB/libusbK/libusb0.
By default this reader is claimed by the Windows Biometric Framework (WBF)
driver, which is what lets Windows Hello / official DigitalPersona software
use it. Rebinding it to WinUSB breaks Windows Hello fingerprint login (and
any other biometric software) for this device until reverted.

1. Get Zadig: https://zadig.akeo.ie/
2. **Options > List All Devices**
3. Find the entry matching exactly `U.are.U® 4500 Fingerprint Reader`
   (`USB\VID_05BA&PID_000A`). Don't pick anything else in the list.
4. Target driver: **WinUSB** > **Replace Driver**.
5. To revert: Device Manager > find the reader > Uninstall device (check
   "delete the driver") > unplug/replug to restore the original WBF driver.

## Build (Code::Blocks)

1. Open `printCatcher.cbp`.
2. Project's compiler must be a working GNU Fortran install — Toolchain
   executables should point at your actual gfortran, e.g.
   `C:\Strawberry\c\bin\gfortran.exe` (not the default `mingw32-gfortran.exe`,
   which typically doesn't exist).
3. Build. `lib/libusb-1.0.dll` must be copied next to the built `.exe`
   (`bin/Debug/` or `bin/Release/`) to run.

## Layout

- `main.f90` — the program, including `bind(C)` interface declarations for
  the libusb functions in use
- `include/libusb.h` — reference copy of the libusb C header (not consumed
  by the Fortran build, kept for looking up signatures)
- `lib/` — prebuilt libusb-1.0 MinGW64 binaries (official libusb GitHub
  release v1.0.30)
