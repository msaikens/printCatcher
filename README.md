# printCatcher

Raw USB communication with a DigitalPersona U.are.U 4500 fingerprint reader
(`VID_05BA&PID_000A`), written in Fortran via `ISO_C_BINDING` calling directly
into libusb-1.0's C API. No official DigitalPersona SDK, no libfprint
dependency — the protocol is an original implementation informed by the
publicly documented, reverse-engineered protocol from the LGPL `libfprint`
project's `uru4000.c` driver.

## Why Fortran

Learning exercise: binding a modern Fortran program directly to a C ABI
library (libusb) via `bind(C)` interface blocks, exploring how Fortran's
pointer/value semantics map onto C's pointer types.

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
