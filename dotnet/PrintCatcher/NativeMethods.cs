using System.Runtime.InteropServices;

namespace PrintCatcher;

internal static class NativeMethods
{
    private const string DllName = "printcatcher_native";

    [DllImport(DllName)]
    public static extern int pc_init();

    [DllImport(DllName)]
    public static extern int pc_open();

    [DllImport(DllName)]
    public static extern int pc_capture(
        [Out] byte[] buffer,
        int bufferLen,
        int timeoutMs,
        out int width,
        out int height,
        out int bpp,
        out int imageSize);

    [DllImport(DllName)]
    public static extern int pc_close();

    [DllImport(DllName)]
    public static extern int pc_exit();
}
