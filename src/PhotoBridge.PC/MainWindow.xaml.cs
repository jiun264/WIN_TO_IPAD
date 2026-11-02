using Microsoft.Win32;
using PhotoBridge.PC.Models;
using PhotoBridge.PC.Services;
using PhotoBridge.PC.Services.Transfer;
using System.Collections.ObjectModel;
using System.IO;
using System.Windows;

namespace PhotoBridge.PC;

public partial class MainWindow : Window
{
    private readonly PhotoFolderScanner _scanner = new();
    private readonly ITransferServer _transferServer = new NativeTransferServer();
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
        var selectedPhotos = _photos.Where(photo => photo.IsSelected).ToArray();
        try
        {
            var result = _transferServer.Start(selectedPhotos, 8765);
            MessageBox.Show(this, result.Message,
                result.IsSuccess ? "PhotoBridge" : "傳輸服務尚未就緒",
                MessageBoxButton.OK,
                result.IsSuccess ? MessageBoxImage.Information : MessageBoxImage.Warning);
        }
        catch (DllNotFoundException ex)
        {
            MessageBox.Show(this,
                $"找不到 C++ 傳輸核心。請先依 README 建置原生專案。\n{ex.Message}",
                "缺少原生元件", MessageBoxButton.OK, MessageBoxImage.Error);
        }
        catch (EntryPointNotFoundException ex)
        {
            MessageBox.Show(this, $"C++ 傳輸核心版本不相容：{ex.Message}",
                "原生元件錯誤", MessageBoxButton.OK, MessageBoxImage.Error);
        }
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