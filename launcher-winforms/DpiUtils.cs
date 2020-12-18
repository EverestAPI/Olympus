using MonoMod.Utils;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public static class DpiUtils {

        public static d_SetProcessDpiAwarenessContext SetProcessDpiAwarenessContext;
        [UnmanagedFunctionPointer(CallingConvention.StdCall, SetLastError = true)]
        public delegate bool d_SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT dpiFlag);

        public static d_SetProcessDpiAwareness SetProcessDpiAwareness;
        [UnmanagedFunctionPointer(CallingConvention.StdCall, SetLastError = true)]
        public delegate bool d_SetProcessDpiAwareness(PROCESS_DPI_AWARENESS awareness);

        public static d_SetProcessDPIAware SetProcessDPIAware;
        [UnmanagedFunctionPointer(CallingConvention.StdCall, SetLastError = true)]
        public delegate bool d_SetProcessDPIAware();

        public enum PROCESS_DPI_AWARENESS {
            Process_DPI_Unaware = 0,
            Process_System_DPI_Aware = 1,
            Process_Per_Monitor_DPI_Aware = 2
        }

        public enum DPI_AWARENESS_CONTEXT {
            DPI_AWARENESS_CONTEXT_UNAWARE = 16,
            DPI_AWARENESS_CONTEXT_SYSTEM_AWARE = 17,
            DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE = 18,
            DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = 34
        }

        static DpiUtils() {
            if (DynDll.TryOpenLibrary("user32.dll", out IntPtr p_user32)) {
                if (p_user32.TryGetFunction("SetProcessDpiAwarenessContext", out IntPtr p_SetProcessDpiAwarenessContext))
                    SetProcessDpiAwarenessContext = p_SetProcessDpiAwarenessContext.AsDelegate<d_SetProcessDpiAwarenessContext>();

                if (p_user32.TryGetFunction("SetProcessDPIAware", out IntPtr p_SetProcessDPIAware))
                    SetProcessDPIAware = p_SetProcessDPIAware.AsDelegate<d_SetProcessDPIAware>();
            }

            if (DynDll.TryOpenLibrary("SHCore.dll", out IntPtr p_SHCore)) {
                if (p_SHCore.TryGetFunction("SetProcessDpiAwareness", out IntPtr p_SetProcessDpiAwareness))
                    SetProcessDpiAwareness = p_SetProcessDpiAwareness.AsDelegate<d_SetProcessDpiAwareness>();
            }
        }

    }
}
