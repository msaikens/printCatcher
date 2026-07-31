namespace PrintCatcher;

/// <summary>
/// Wraps a DigitalPersona U.are.U 4500 fingerprint reader via the official
/// SDK (dpfpdd.dll), through a small native Fortran shim (printcatcher.dll).
/// Only one reader can be open at a time (matches the underlying native API).
/// </summary>
public sealed class FingerprintReader : IDisposable
{
    private const int DefaultBufferSize = 500_000;

    private bool _initialized;
    private bool _opened;
    private bool _disposed;

    public FingerprintReader()
    {
        int rc = NativeMethods.pc_init();
        if (rc != 0)
        {
            throw new FingerprintReaderException("pc_init", rc);
        }
        _initialized = true;
    }

    /// <summary>
    /// Finds and opens the first connected reader. Must be called before Capture().
    /// </summary>
    public void Open()
    {
        ThrowIfDisposed();
        int rc = NativeMethods.pc_open();
        if (rc != 0)
        {
            throw new FingerprintReaderException("pc_open", rc);
        }
        _opened = true;
    }

    /// <summary>
    /// Blocks until a finger is presented and captures one image.
    /// </summary>
    /// <param name="timeoutMs">Milliseconds to wait, or -1 for no timeout.</param>
    public FingerprintImage Capture(int timeoutMs = -1)
    {
        ThrowIfDisposed();
        if (!_opened)
        {
            throw new InvalidOperationException("Call Open() before Capture().");
        }

        var buffer = new byte[DefaultBufferSize];
        int rc = NativeMethods.pc_capture(
            buffer, buffer.Length, timeoutMs,
            out int width, out int height, out int bpp, out int imageSize);

        if (rc != 0)
        {
            throw new FingerprintReaderException("pc_capture", rc);
        }

        if (imageSize != buffer.Length)
        {
            Array.Resize(ref buffer, imageSize);
        }

        return new FingerprintImage(width, height, bpp, buffer);
    }

    public void Dispose()
    {
        if (_disposed) return;

        if (_opened)
        {
            NativeMethods.pc_close();
            _opened = false;
        }
        if (_initialized)
        {
            NativeMethods.pc_exit();
            _initialized = false;
        }

        _disposed = true;
        GC.SuppressFinalize(this);
    }

    private void ThrowIfDisposed()
    {
        if (_disposed)
        {
            throw new ObjectDisposedException(nameof(FingerprintReader));
        }
    }

    ~FingerprintReader()
    {
        Dispose();
    }
}

public sealed class FingerprintReaderException : Exception
{
    public string NativeCall { get; }
    public int NativeErrorCode { get; }

    public FingerprintReaderException(string nativeCall, int nativeErrorCode)
        : base($"{nativeCall} failed with code {nativeErrorCode} (0x{nativeErrorCode:X8})")
    {
        NativeCall = nativeCall;
        NativeErrorCode = nativeErrorCode;
    }
}
