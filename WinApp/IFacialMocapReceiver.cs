using System;
using System.ComponentModel;
using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Globalization;

namespace VTubeLink
{
    public class IFacialMocapReceiver : INotifyPropertyChanged
    {
        private bool _isReceiving;
        public bool IsReceiving
        {
            get => _isReceiving;
            private set
            {
                if (_isReceiving != value)
                {
                    _isReceiving = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(IsReceiving)));
                }
            }
        }

        private CapturedData _latestData = new();
        public CapturedData LatestData
        {
            get => _latestData;
            private set
            {
                _latestData = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(LatestData)));
            }
        }

        public event PropertyChangedEventHandler? PropertyChanged;

        private UdpClient? _udpClient;
        private CancellationTokenSource? _cancellationTokenSource;
        private const int Port = 49983;

        public async Task StartAsync(string ipAddress)
        {
            if (string.IsNullOrWhiteSpace(ipAddress)) return;

            Stop();

            _cancellationTokenSource = new CancellationTokenSource();
            var token = _cancellationTokenSource.Token;

            try
            {
                _udpClient = new UdpClient();
                // Send init ping to iPhone
                var initString = "iFacialMocap_sahuasouryya9218sauhuiayeta91555dy3719";
                var initBytes = Encoding.UTF8.GetBytes(initString);
                _udpClient.Connect(ipAddress, Port);
                await _udpClient.SendAsync(initBytes, initBytes.Length);
                AppLogger.Log("UDP", "Sent initialization string to iFacialMocap");

                // Start listening
                _udpClient.Close(); // Close the connected client
                _udpClient = new UdpClient(Port); // Reopen for listening on the port
                IsReceiving = true;

                _ = Task.Run(async () =>
                {
                    try
                    {
                        while (!token.IsCancellationRequested)
                        {
                            var result = await _udpClient.ReceiveAsync(token);
                            var message = Encoding.UTF8.GetString(result.Buffer);
                            ProcessData(message);
                        }
                    }
                    catch (OperationCanceledException) { }
                    catch (SocketException ex)
                    {
                        AppLogger.Log("UDP", $"SocketException: {ex.Message}");
                    }
                    finally
                    {
                        IsReceiving = false;
                    }
                }, token);
            }
            catch (Exception ex)
            {
                AppLogger.Log("UDP", $"Failed to start receiver: {ex.Message}");
                IsReceiving = false;
            }
        }

        public void Stop()
        {
            _cancellationTokenSource?.Cancel();
            _cancellationTokenSource?.Dispose();
            _cancellationTokenSource = null;

            _udpClient?.Close();
            _udpClient?.Dispose();
            _udpClient = null;

            IsReceiving = false;
        }

        private void ProcessData(string rawData)
        {
            var paramsDict = new System.Collections.Generic.Dictionary<string, float[]>();

            var paramStrs = rawData.Trim('|').Split('|');
            foreach (var paramStr in paramStrs)
            {
                if (paramStr.Contains('#'))
                {
                    var parts = paramStr.Split('#');
                    if (parts.Length == 2)
                    {
                        var key = parts[0];
                        var valStrs = parts[1].Split(',');
                        var vals = new float[valStrs.Length];
                        for (int i = 0; i < valStrs.Length; i++)
                        {
                            if (float.TryParse(valStrs[i], NumberStyles.Float, CultureInfo.InvariantCulture, out float val))
                            {
                                vals[i] = val;
                            }
                        }
                        paramsDict[key] = vals;
                    }
                }
                else if (paramStr.Contains('-'))
                {
                    var parts = paramStr.Split('-');
                    if (parts.Length == 2)
                    {
                        var key = parts[0];
                        if (float.TryParse(parts[1], NumberStyles.Float, CultureInfo.InvariantCulture, out float val))
                        {
                            paramsDict[key] = [val / 100.0f];
                        }
                    }
                }
            }

            var newData = new CapturedData();

            foreach (var blendshape in Constants.BlendshapeNames)
            {
                if (paramsDict.TryGetValue(blendshape, out var vals) && vals.Length > 0)
                {
                    newData.Blendshapes[blendshape] = vals[0];
                }
                else
                {
                    newData.Blendshapes[blendshape] = 0.0f;
                }
            }

            if (paramsDict.TryGetValue("=head", out var headVals) && headVals.Length >= 6)
            {
                newData.HeadRotationX = headVals[0];
                newData.HeadRotationY = headVals[1];
                newData.HeadRotationZ = headVals[2];
                newData.HeadPositionX = headVals[3];
                newData.HeadPositionY = headVals[4];
                newData.HeadPositionZ = headVals[5];
            }

            if (paramsDict.TryGetValue("rightEye", out var rightEye) && rightEye.Length >= 3)
            {
                newData.RightEyeRotationX = rightEye[0];
                newData.RightEyeRotationY = rightEye[1];
                newData.RightEyeRotationZ = rightEye[2];
            }

            if (paramsDict.TryGetValue("leftEye", out var leftEye) && leftEye.Length >= 3)
            {
                newData.LeftEyeRotationX = leftEye[0];
                newData.LeftEyeRotationY = leftEye[1];
                newData.LeftEyeRotationZ = leftEye[2];
            }

            LatestData = newData;
        }
    }
}
