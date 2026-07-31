using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

namespace PrintCatcher;

// .NET only auto-probes runtimes/<rid>/native/ for a native dependency when
// this library is consumed as a real, restored NuGet package -- the deps.json
// wiring that drives that probing isn't generated for a plain ProjectReference
// (e.g. a sample app in the same repo/solution). Registering our own resolver
// makes native DLL loading work identically either way, instead of silently
// depending on which reference style a consumer happens to use.
internal static class NativeLibraryResolver
{
#pragma warning disable CA2255 // intentional: this is exactly what ModuleInitializer is for here
    [ModuleInitializer]
    public static void Initialize()
    {
        NativeLibrary.SetDllImportResolver(typeof(NativeLibraryResolver).Assembly, Resolve);
    }

    private static nint Resolve(string libraryName, Assembly assembly, DllImportSearchPath? searchPath)
    {
        if (libraryName != "printcatcher_native")
        {
            return nint.Zero; // not ours -- let the default resolver handle it
        }

        string candidate = Path.Combine(
            AppContext.BaseDirectory, "runtimes", "win-x64", "native", "printcatcher_native.dll");

        if (File.Exists(candidate) && NativeLibrary.TryLoad(candidate, out nint handle))
        {
            return handle;
        }

        return nint.Zero; // fall back to default resolution
    }
}
