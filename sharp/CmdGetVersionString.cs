using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public class CmdGetVersionString : Cmd<string, string> {
        public override string Run(string path) {
            try {
                using (ModuleDefinition game = ModuleDefinition.ReadModule(Path.Combine(path, "Celeste.exe"))) {
                    TypeDefinition t_Celeste = game.GetType("Celeste.Celeste");
                    if (t_Celeste == null)
                        return "Not Celeste!";

                    // Find Celeste .ctor (luckily only has one)

                    string versionString = null;
                    int[] versionInts = null;

                    MethodDefinition c_Celeste =
                        t_Celeste.FindMethod("System.Void orig_ctor_Celeste()") ??
                        t_Celeste.FindMethod("System.Void .ctor()");

                    if (c_Celeste != null && c_Celeste.HasBody) {
                        Mono.Collections.Generic.Collection<Instruction> instrs = c_Celeste.Body.Instructions;
                        for (int instri = 0; instri < instrs.Count; instri++) {
                            Instruction instr = instrs[instri];
                            MethodReference c_Version = instr.Operand as MethodReference;
                            if (instr.OpCode != OpCodes.Newobj || c_Version?.DeclaringType?.FullName != "System.Version")
                                continue;

                            // We're constructing a System.Version - check if all parameters are of type int.
                            bool c_Version_intsOnly = true;
                            foreach (ParameterReference param in c_Version.Parameters)
                                if (param.ParameterType.MetadataType != MetadataType.Int32) {
                                    c_Version_intsOnly = false;
                                    break;
                                }

                            if (c_Version_intsOnly) {
                                // Assume that ldc.i4* instructions are right before the newobj.
                                versionInts = new int[c_Version.Parameters.Count];
                                for (int i = -versionInts.Length; i < 0; i++)
                                    versionInts[i + versionInts.Length] = instrs[i + instri].GetInt();
                            }

                            if (c_Version.Parameters.Count == 1 && c_Version.Parameters[0].ParameterType.MetadataType == MetadataType.String) {
                                // Assume that a ldstr is right before the newobj.
                                versionString = instrs[instri - 1].Operand as string;
                            }

                            // Don't check any other instructions.
                            break;
                        }
                    }

                    // Construct the version from our gathered data.
                    Version version = new Version();
                    if (versionString != null)
                        version = new Version(versionString);
                    if (versionInts == null || versionInts.Length == 0)
                        version = new Version();
                    else if (versionInts.Length == 2)
                        version = new Version(versionInts[0], versionInts[1]);
                    else if (versionInts.Length == 3)
                        version = new Version(versionInts[0], versionInts[1], versionInts[2]);
                    else if (versionInts.Length == 4)
                        version = new Version(versionInts[0], versionInts[1], versionInts[2], versionInts[3]);

                    string status = $"Celeste {version}-{(game.AssemblyReferences.Any(r => r.Name == "FNA") ? "fna" : "xna")}";

                    TypeDefinition t_Everest = game.GetType("Celeste.Mod.Everest");
                    if (t_Everest != null) {
                        // The first operation in .cctor is ldstr with the version string.
                        string versionMod = (string) t_Everest.FindMethod("System.Void .cctor()").Body.Instructions[0].Operand;
                        int versionSplitIndex = versionMod.IndexOf('-');
                        status = $"{status} + Everest {versionMod}";
                    }

                    return status;
                }

            } catch (Exception e) {
                return $"? - {e.Message}";
            }
        }
    }
}
