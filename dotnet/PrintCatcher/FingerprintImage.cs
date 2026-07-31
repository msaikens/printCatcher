namespace PrintCatcher;

/// <summary>
/// A captured fingerprint image: raw grayscale pixel data plus its dimensions.
/// </summary>
public sealed class FingerprintImage
{
    public int Width { get; }
    public int Height { get; }
    public int BitsPerPixel { get; }
    public byte[] PixelData { get; }

    internal FingerprintImage(int width, int height, int bitsPerPixel, byte[] pixelData)
    {
        Width = width;
        Height = height;
        BitsPerPixel = bitsPerPixel;
        PixelData = pixelData;
    }

    /// <summary>
    /// Writes this image out as a PGM (P5) file -- viewable in GIMP, IrfanView,
    /// or converted with ffmpeg. Only valid for 8-bit-per-pixel grayscale images.
    /// </summary>
    public void SaveAsPgm(string path)
    {
        if (BitsPerPixel != 8)
        {
            throw new NotSupportedException(
                $"SaveAsPgm only supports 8bpp images; this image is {BitsPerPixel}bpp.");
        }

        var header = $"P5\n{Width} {Height}\n255\n";
        using var stream = File.Create(path);
        var headerBytes = System.Text.Encoding.ASCII.GetBytes(header);
        stream.Write(headerBytes, 0, headerBytes.Length);
        stream.Write(PixelData, 0, PixelData.Length);
    }
}
