using System.Configuration;
using System.Data;
using System.Windows;

namespace VTubeLink;

/// <summary>
/// Interaction logic for App.xaml
/// </summary>
public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        this.DispatcherUnhandledException += App_DispatcherUnhandledException;
        base.OnStartup(e);
    }

    private void App_DispatcherUnhandledException(object sender, System.Windows.Threading.DispatcherUnhandledExceptionEventArgs e)
    {
        MessageBox.Show($"FATAL ERROR: {e.Exception.Message}\n\n{e.Exception.InnerException?.Message}\n\n{e.Exception.StackTrace}", "VTubeLink Error", MessageBoxButton.OK, MessageBoxImage.Error);
        e.Handled = true;
        Application.Current.Shutdown();
    }
}

