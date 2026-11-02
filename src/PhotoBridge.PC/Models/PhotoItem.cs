using System.ComponentModel;
using System.IO;
using System.Runtime.CompilerServices;

namespace PhotoBridge.PC.Models;

public sealed class PhotoItem : INotifyPropertyChanged
{
    private bool _isSelected = true;

    public PhotoItem(string path)
    {
        Path = path;
        var file = new FileInfo(path);
        FileName = file.Name;
        Format = file.Extension.TrimStart('.').ToUpperInvariant();
        SizeBytes = file.Length;
    }

    public string Path { get; }
    public string FileName { get; }
    public string Format { get; }
    public long SizeBytes { get; }
    public string SizeLabel => SizeBytes >= 1024L * 1024 * 1024
        ? $"{SizeBytes / (1024d * 1024 * 1024):N2} GB"
        : $"{SizeBytes / (1024d * 1024):N1} MB";

    public bool IsSelected
    {
        get => _isSelected;
        set
        {
            if (_isSelected == value)
            {
                return;
            }

            _isSelected = value;
            OnPropertyChanged();
        }
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
}
