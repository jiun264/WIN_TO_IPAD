using System.Collections.ObjectModel;
using System.IO;
using System.Windows;
using Microsoft.Win32;
using PhotoBridge.PC.Models;
using PhotoBridge.PC.Services;
using PhotoBridge.PC.Services.Transfer;

namespace PhotoBridge.PC;

public partial class MainWindow : Window
{
    private readonly PhotoFolderScanner _scanner = new();
    private readonly ITransferServer _transferServer = new KestrelTransferServer();
    private readonly ObservableCollection<PhotoItem> _photos = [];
    private string _activeAddress = "";

    public MainWindow()
    {
        InitializeComponent();
        PhotoGrid.ItemsSource = _photos;

        _transferServer.FileTransferred += OnFileTransferred;
        _transferServer.LogMessage += OnLogMessage;
        Closing += async (_, _) => await _transferServer.StopAsync();
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

    private async void SendButton_Click(object sender, RoutedEventArgs e)
    {
        var selectedPhotos = _photos.Where(photo => photo.IsSelected).ToArray();
        if (selectedPhotos.Length == 0)
        {
            MessageBox.Show(this, "請先勾選至少一張欲傳輸的照片。", "提示", MessageBoxButton.OK, MessageBoxImage.Information);
            return;
        }

        SendButton.IsEnabled = false;
        SendButton.Content = "啟動中...";

        var result = await _transferServer.StartAsync(selectedPhotos, 8765);
        if (result.IsSuccess)
        {
            ServerStatusPanel.Visibility = Visibility.Visible;
            _activeAddress = result.LocalAddresses?.Count > 0
                ? $"http://{result.LocalAddresses[0]}:{result.Port}"
                : $"http://127.0.0.1:{result.Port}";

            ServerAddressText.Text = _activeAddress;
            PairingCodeText.Text = result.PairingCode ?? "------";
            ServerLogText.Text = $"已就緒！等待 iPad 連線，共 {selectedPhotos.Length} 張照片。";

            SendButton.Content = "服務運行中";
        }
        else
        {
            MessageBox.Show(this, result.Message, "啟動失敗", MessageBoxButton.OK, MessageBoxImage.Error);
            SendButton.IsEnabled = true;
            SendButton.Content = "啟動直傳服務";
        }
    }

    private async void StopServerButton_Click(object sender, RoutedEventArgs e)
    {
        await _transferServer.StopAsync();
        ServerStatusPanel.Visibility = Visibility.Collapsed;
        SendButton.IsEnabled = _photos.Count > 0;
        SendButton.Content = "啟動直傳服務";
    }

    private void CopyAddressButton_Click(object sender, RoutedEventArgs e)
    {
        if (!string.IsNullOrEmpty(_activeAddress))
        {
            Clipboard.SetText(_activeAddress);
            MessageBox.Show(this, $"已複製位址至剪貼簿：{_activeAddress}", "已複製", MessageBoxButton.OK, MessageBoxImage.Information);
        }
    }

    private void SelectAllButton_Click(object sender, RoutedEventArgs e)
    {
        foreach (var photo in _photos)
        {
            photo.IsSelected = true;
        }
        UpdateSelectionSummary();
    }

    private void DeselectAllButton_Click(object sender, RoutedEventArgs e)
    {
        foreach (var photo in _photos)
        {
            photo.IsSelected = false;
        }
        UpdateSelectionSummary();
    }

    private void OnFileTransferred(string fileName)
    {
        Dispatcher.Invoke(() =>
        {
            ServerLogText.Text = $"[{DateTime.Now:HH:mm:ss}] 成功直傳至 iPad: {fileName}";
        });
    }

    private void OnLogMessage(string msg)
    {
        Dispatcher.Invoke(() =>
        {
            ServerLogText.Text = msg;
        });
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
