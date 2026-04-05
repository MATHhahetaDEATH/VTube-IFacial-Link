using System;
using System.Collections.ObjectModel;
using System.Windows;

namespace VTubeLink
{
    public class LogLine
    {
        public string Tag { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
    }

    public static class AppLogger
    {
        public static ObservableCollection<LogLine> Logs { get; } = new ObservableCollection<LogLine>();

        public static void Log(string tag, string message)
        {
            Application.Current.Dispatcher.InvokeAsync(() =>
            {
                Logs.Add(new LogLine { Tag = tag, Message = $"[{DateTime.Now:HH:mm:ss}] {message}" });
                if (Logs.Count > 500)
                {
                    Logs.RemoveAt(0);
                }
            });
        }
    }
}
