using PrintCatcher;

Console.WriteLine("Opening reader...");
using var reader = new FingerprintReader();
reader.Open();

Console.WriteLine("Waiting for finger...");
var image = reader.Capture();

Console.WriteLine($"Captured {image.Width}x{image.Height}, {image.BitsPerPixel}bpp, {image.PixelData.Length} bytes");

image.SaveAsPgm("nuget_test_capture.pgm");
Console.WriteLine("Wrote nuget_test_capture.pgm");
