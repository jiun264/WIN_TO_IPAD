using Microsoft.Win32;
using PhotoBridge.PC.Models;
using PhotoBridge.PC.Services;
using System.Collections.ObjectModel;
using System.IO;
using System.Windows;

namespace PhotoBridge.PC;

public partial class MainWindow : Window
{
    private readonly PhotoFolderScanner _scanner = new();
    private readonly ObservableCollection<PhotoItem> _photos = [];

    public MainWindow()
    {
        InitializeComponent();
        PhotoGrid.ItemsSource = _photos;
    }

    private void ChooseFolderButton_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new OpenFolderDialog
        {
            Title = "選擇包含照片的資料夾",
            Multiselect = false
        };

        if (dialog.ShowDialog(this) != true)
        {
            return;
        }

        try
        {
            var photos = _scanner.Scan(dialog.FolderName);
            _photos.Clear();
            foreach (var photo in photos)
            {
                photo.PropertyChanged += (_, _) => UpdateSelectionSummary();
                _photos.Add(photo);
            }

            FolderPathText.Text = dialog.FolderName;
            SendButton.IsEnabled = _photos.Count > 0;
            UpdateSelectionSummary();
        }
        catch (IOException ex)
        {
            MessageBox.Show(this, $"無法讀取資料夾：{ex.Message}", "讀取失敗",
                MessageBoxButton.OK, MessageBoxImage.Error);
        }
        catch (UnauthorizedAccessException ex)
        {
            MessageBox.Show(this, $"沒有權限讀取資料夾：{ex.Message}", "讀取失敗",
                MessageBoxButton.OK, MessageBoxImage.Error);
        }
    }

    private void SendButton_Click(object sender, RoutedEventArgs e)
    {
        MessageBox.Show(this,
            "照片挑選介面已就緒；區域網路配對與可恢復傳輸服務尚待實作。",
            "PhotoBridge 開發中", MessageBoxButton.OK, MessageBoxImage.Information);
    }

    private void UpdateSelectionSummary()
    {
        var selected = _photos.Where(photo => photo.IsSelected).ToArray();
        var totalBytes = selected.Sum(photo => photo.SizeBytes);
        var totalLabel = totalBytes >= 1024L * 1024 * 1024
            ? $"{totalBytes / (1024d * 1024 * 1024):N2} GB"
            : $"{totalBytes / (1024d * 1024):N1} MB";

        SelectionSummaryText.Text = _photos.Count == 0
            ? "此資料夾沒有支援的照片格式"
            : $"已選取 {selected.Length} / {_photos.Count} 張，合計 {totalLabel}";
    }
}