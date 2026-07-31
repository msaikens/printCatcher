# PrintCatcher

.NET wrapper for a DigitalPersona U.are.U 4500 fingerprint reader.

Calls into the official DigitalPersona U.are.U SDK (`dpfpdd.dll`) through a
small native Fortran shim, rather than reimplementing the reader's USB
protocol. **Windows-only.**

## Requirements

- Windows, x64.
- The official U.are.U SDK installed (provides `dpfpdd.dll` and its own
  device driver). Get it from HID Global's developer portal.
- A U.are.U 4500 reader connected, using its normal Windows driver (no
  special setup needed — just don't rebind it to WinUSB/libusb).

## Usage

```csharp
using PrintCatcher;

using var reader = new FingerprintReader();
reader.Open();

var image = reader.Capture(); // blocks until a finger is presented
Console.WriteLine($"{image.Width}x{image.Height}, {image.BitsPerPixel}bpp");

image.SaveAsPgm("capture.pgm");
```

Works the same from VB.NET, F#, or any other .NET language — this is a
normal compiled assembly, nothing C#-specific about it.

## API

- `FingerprintReader()` — initializes the underlying SDK.
- `.Open()` — finds and opens the first connected reader.
- `.Capture(int timeoutMs = -1)` — blocks until a finger is presented (or
  the timeout elapses), returns a `FingerprintImage`.
- `.Dispose()` — releases the reader and the SDK. Only one reader can be
  open at a time.
- `FingerprintImage.SaveAsPgm(path)` — writes the raw capture as a PGM
  (P5) file, viewable in GIMP/IrfanView or convertible with ffmpeg.

Failures throw `FingerprintReaderException`, which carries the underlying
native error code (`NativeErrorCode`) alongside the message.

## Source

Full source, the native shim it's built on, and the story of how this was
built (including a from-scratch reverse-engineering detour into the
reader's raw USB protocol): https://github.com/msaikens/printCatcher
