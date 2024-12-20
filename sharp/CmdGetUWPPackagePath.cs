#if WIN32
using System;
using System.Runtime.InteropServices;

namespace Olympus {
    public unsafe class CmdGetUWPPackagePath : Cmd<string, string> {
        public override bool Taskable => true;
        public override string Run(string package) {
            IntPtr buffer = IntPtr.Zero;
            try {
                uint count;
                uint bufferLength;
                Error status;


                // family -> full name

                count = 0;
                bufferLength = 0;
                status = GetPackagesByPackageFamily(package, ref count, (char**) 0, ref bufferLength, (char*) 0);
                if (count == 0 || bufferLength == 0 || (status != Error.Success && status != Error.InsufficientBuffer))
                    return null;

                char*[] packageFullNames = new char*[count];
                buffer = Marshal.AllocHGlobal((int) bufferLength * sizeof(char));

                fixed (char** packageFullNamesPtr = &packageFullNames[0])
                    status = GetPackagesByPackageFamily(package, ref count, packageFullNamesPtr, ref bufferLength, (char*) buffer);
                if (status != Error.Success)
                    return null;

                // Only the first full package name is required anyway.
                package = new string(packageFullNames[0]);
                packageFullNames = null;
                Marshal.FreeHGlobal(buffer);
                buffer = IntPtr.Zero;


                // full name -> path

                bufferLength = 0;
                status = GetPackagePathByFullName(package, ref bufferLength, (char*) 0);
                if (bufferLength == 0 || (status != Error.Success && status != Error.InsufficientBuffer))
                    return null;

                buffer = Marshal.AllocHGlobal((int) bufferLength * sizeof(char));
                status = GetPackagePathByFullName(package, ref bufferLength, (char*) buffer);
                if (status != Error.Success)
                    return null;

                package = new string((char*) buffer);
                Marshal.FreeHGlobal(buffer);
                buffer = IntPtr.Zero;


                return package;

            } catch {
                return null;

            } finally {
                if (buffer != IntPtr.Zero)
                    Marshal.FreeHGlobal(buffer);
            }
        }

        public enum Error : long {
            Success = 0x00,
            InsufficientBuffer = 0x7A
        }

        public enum PackagePathType : long {
            Install,
            Mutable,
            Effective,
            MachineExternal,
            UserExternal,
            EffectiveExternal
        }

        [DllImport("kernel32")]
        public static extern Error GetPackagesByPackageFamily(
            [MarshalAs(UnmanagedType.LPWStr)] string packageFamilyName,
            ref uint count,
            char** packageFullNames,
            ref uint bufferLength,
            char* buffer
        );

        [DllImport("kernel32")]
        public static extern Error GetPackagePathByFullName(
            [MarshalAs(UnmanagedType.LPWStr)] string packageFullName,
            ref uint pathLength,
            char* path
        );

    }
}
#endif