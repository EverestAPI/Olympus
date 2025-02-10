import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

// I hate PowerShell so here we are
public class SemiTrimmedOlympusBuild {
    public static void main(String[] args) throws Exception {
        Path outputFolder = Paths.get("sharp/bin/Release/net8.0/win-x86/publish");

        // trimmed build
        build(true);

        // list files
        List<Path> files;
        try (Stream<Path> paths = Files.walk(outputFolder)) {
            files = paths.filter(Files::isRegularFile).collect(Collectors.toList());
        }
        System.out.println("File list: " + formatFileList(files, outputFolder));

        // purge the directory
        try (Stream<Path> paths = Files.walk(outputFolder)) {
            if (!paths.sorted(Comparator.reverseOrder()).map(Path::toFile).allMatch(File::delete)) {
                throw new IOException("Failed cleaning up build directory: " + outputFolder);
            }
        }

        // untrimmed build
        build(false);

        // prune files that weren't part of the trimmed build
        List<Path> toDelete;
        try (Stream<Path> paths = Files.walk(outputFolder)) {
            toDelete = paths.filter(f -> Files.isRegularFile(f) && !files.contains(f)).collect(Collectors.toList());
        }
        System.out.println("Deleting files: " + formatFileList(toDelete, outputFolder));

        if (!toDelete.stream().map(Path::toFile).allMatch(File::delete)) {
            throw new IOException("Failed cleaning up build directory: " + outputFolder);
        }
    }

    private static void build(boolean trimmed) throws Exception {
        System.out.println("Building with trimming = " + trimmed + "...");
        Process build = new ProcessBuilder("dotnet", "publish", "--self-contained", "--runtime", "win-x86", "-p:PublishTrimmed=" + trimmed, "sharp/Olympus.Sharp.csproj")
                .inheritIO().start();
        build.waitFor();
        if (build.exitValue() != 0) throw new Exception("dotnet publish failed with exit code " + build.exitValue());
    }

    private static String formatFileList(List<Path> files, Path relativeTo) {
        return "[\"" + files.stream().map(p -> relativeTo.relativize(p).toString())
                .collect(Collectors.joining("\", \"")) + "\"]";
    }
}
