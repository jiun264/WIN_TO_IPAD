using System.IO;
using PhotoBridge.PC.Models;

namespace PhotoBridge.PC.Services;

public sealed class PhotoFolderScanner
{
    private static readonly HashSet<string> SupportedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".nef", ".jpg", ".jpeg", ".tif", ".tiff", ".png", ".dng"
    };

    public IReadOnlyList<PhotoItem> Scan(string folderPath) =>
        Directory.EnumerateFiles(folderPath)
            .Where(path => SupportedExtensions.Contains(Path.GetExtension(path)))
            .OrderBy(path => path, StringComparer.OrdinalIgnoreCase)
            .Select(path => new PhotoItem(path))
            .ToArray();
}
