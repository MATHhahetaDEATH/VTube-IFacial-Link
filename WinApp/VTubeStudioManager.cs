using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Linq;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace VTubeLink
{
    public class VTubeStudioManager : INotifyPropertyChanged
    {
        private bool _isConnected;
        public bool IsConnected
        {
            get => _isConnected;
            private set
            {
                if (_isConnected != value)
                {
                    _isConnected = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(IsConnected)));
                }
            }
        }

        private bool _isAuthenticated;
        public bool IsAuthenticated
        {
            get => _isAuthenticated;
            private set
            {
                if (_isAuthenticated != value)
                {
                    _isAuthenticated = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(IsAuthenticated)));
                }
            }
        }

        public event PropertyChangedEventHandler? PropertyChanged;

        private ClientWebSocket? _webSocket;
        private readonly Uri _url = new("ws://127.0.0.1:8001");
        
        private const string PluginName = "VTube-IFacial-Link-Windows";
        private const string PluginDeveloper = "xuan25";
        private const string ApiVersion = "1.0";

        private bool _injectionLoopRunning;
        private bool _shouldReconnect;
        private CancellationTokenSource? _cancellationTokenSource;

        public IFacialMocapReceiver? DataSource { get; set; }

        public async Task ConnectAsync()
        {
            _shouldReconnect = true;
            _cancellationTokenSource = new CancellationTokenSource();
            
            await ConnectInternalAsync();
        }

        private async Task ConnectInternalAsync()
        {
            try
            {
                _webSocket = new ClientWebSocket();
                await _webSocket.ConnectAsync(_url, _cancellationTokenSource!.Token);
                IsConnected = true;

                await PerformInitAsync();
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[VTS] Connection failed: {ex.Message}");
                CleanupConnection();
                Reconnect();
            }
        }

        public void Disconnect()
        {
            _shouldReconnect = false;
            _injectionLoopRunning = false;
            _cancellationTokenSource?.Cancel();

            CleanupConnection();
        }

        private void CleanupConnection()
        {
            if (_webSocket != null)
            {
                if (_webSocket.State == WebSocketState.Open)
                {
                    try { _webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closing", CancellationToken.None).Wait(500); } catch { }
                }
                _webSocket.Dispose();
                _webSocket = null;
            }
            IsConnected = false;
            IsAuthenticated = false;
        }

        private void Reconnect()
        {
            if (!_shouldReconnect) return;

            Debug.WriteLine("[VTS] Reconnecting in 3 seconds...");
            Task.Delay(3000).ContinueWith(_ => 
            {
                if (_shouldReconnect && _cancellationTokenSource != null && !_cancellationTokenSource.IsCancellationRequested)
                {
                    _ = ConnectInternalAsync();
                }
            });
        }

        public event Action<MappingUpdate>? MappingUpdated;

        private async Task<JsonElement> SendAndReceiveAsync(object payload)
        {
            if (_webSocket == null || _webSocket.State != WebSocketState.Open)
                throw new InvalidOperationException("WebSocket is not connected");

            var token = _cancellationTokenSource!.Token;
            var jsonString = JsonSerializer.Serialize(payload);
            var bytes = Encoding.UTF8.GetBytes(jsonString);
            
            await _webSocket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, token);

            var buffer = new byte[8192];
            var responseBytes = new List<byte>();
            
            WebSocketReceiveResult result;
            do
            {
                result = await _webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), token);
                if (result.MessageType == WebSocketMessageType.Close)
                {
                    throw new InvalidOperationException("WebSocket closed by server.");
                }
                responseBytes.AddRange(buffer.Take(result.Count));
            } while (!result.EndOfMessage);

            var responseString = Encoding.UTF8.GetString(responseBytes.ToArray());
            return JsonSerializer.Deserialize<JsonElement>(responseString);
        }

        private async Task PerformInitAsync()
        {
            try
            {
                bool authSuccess = await AuthenticateOrRequestTokenAsync();
                if (authSuccess)
                {
                    await CheckAndRegisterParametersAsync();
                    AppLogger.Log("VTS", "Successfully initialized. Starting injection loop.");
                    _ = InjectionLoopAsync();
                }
                else
                {
                    AppLogger.Log("VTS", "Authentication failed. Not starting injection.");
                }
            }
            catch (Exception ex)
            {
                AppLogger.Log("VTS", $"Init failed: {ex.Message}");
                CleanupConnection();
                Reconnect();
            }
        }

        private async Task<bool> AuthenticateOrRequestTokenAsync()
        {
            string? savedToken = ConfigManager.Instance.VtsToken;
            bool success = false;

            if (!string.IsNullOrEmpty(savedToken))
            {
                success = await AuthenticateAsync(savedToken);
                if (!success)
                {
                    string newToken = await RequestTokenAsync();
                    ConfigManager.Instance.VtsToken = newToken;
                    ConfigManager.Instance.Save();
                    success = await AuthenticateAsync(newToken);
                }
            }
            else
            {
                string newToken = await RequestTokenAsync();
                ConfigManager.Instance.VtsToken = newToken;
                ConfigManager.Instance.Save();
                success = await AuthenticateAsync(newToken);
            }

            return success;
        }

        private async Task<string> RequestTokenAsync()
        {
            var payload = new
            {
                apiName = "VTubeStudioPublicAPI",
                apiVersion = ApiVersion,
                requestID = Guid.NewGuid().ToString(),
                messageType = "AuthenticationTokenRequest",
                data = new
                {
                    pluginName = PluginName,
                    pluginDeveloper = PluginDeveloper
                }
            };

            var response = await SendAndReceiveAsync(payload);
            if (response.TryGetProperty("data", out var data) && data.TryGetProperty("authenticationToken", out var tokenObj))
            {
                return tokenObj.GetString() ?? "";
            }
            throw new Exception("No token in response");
        }

        private async Task<bool> AuthenticateAsync(string token)
        {
            var payload = new
            {
                apiName = "VTubeStudioPublicAPI",
                apiVersion = ApiVersion,
                requestID = Guid.NewGuid().ToString(),
                messageType = "AuthenticationRequest",
                data = new
                {
                    pluginName = PluginName,
                    pluginDeveloper = PluginDeveloper,
                    authenticationToken = token
                }
            };

            var response = await SendAndReceiveAsync(payload);
            if (response.TryGetProperty("data", out var data) && data.TryGetProperty("authenticated", out var authenticatedObj))
            {
                bool authenticated = authenticatedObj.GetBoolean();
                IsAuthenticated = authenticated;
                return authenticated;
            }
            return false;
        }

        private async Task CheckAndRegisterParametersAsync()
        {
            var fetchPayload = new
            {
                apiName = "VTubeStudioPublicAPI",
                apiVersion = ApiVersion,
                requestID = Guid.NewGuid().ToString(),
                messageType = "InputParameterListRequest"
            };

            var existingParams = new HashSet<string>();
            var response = await SendAndReceiveAsync(fetchPayload);
            if (response.TryGetProperty("data", out var data) && data.TryGetProperty("customParameters", out var customParamsArray))
            {
                foreach (var param in customParamsArray.EnumerateArray())
                {
                    if (param.TryGetProperty("name", out var nameObj))
                    {
                        existingParams.Add(nameObj.GetString()!);
                    }
                }
            }

            foreach (var paramName in Constants.CustomParams)
            {
                if (!existingParams.Contains(paramName))
                {
                    var createPayload = new
                    {
                        apiName = "VTubeStudioPublicAPI",
                        apiVersion = ApiVersion,
                        requestID = Guid.NewGuid().ToString(),
                        messageType = "ParameterCreationRequest",
                        data = new
                        {
                            parameterName = paramName,
                            explanation = "",
                            min = 0,
                            max = 1,
                            defaultValue = 0
                        }
                    };
                    await SendAndReceiveAsync(createPayload);
                }
            }
        }

        private DateTime _lastBroadcastTime = DateTime.MinValue;

        private async Task InjectionLoopAsync()
        {
            _injectionLoopRunning = true;
            var token = _cancellationTokenSource!.Token;

            var receiveBuffer = new byte[8192];

            while (_injectionLoopRunning && IsConnected && IsAuthenticated && !token.IsCancellationRequested)
            {
                if (DataSource == null)
                {
                    await Task.Delay(16, token);
                    continue;
                }

                var capturedData = DataSource.LatestData;
                var paramsList = DataMapper.BuildParamsDict(capturedData);

                var payload = new
                {
                    apiName = "VTubeStudioPublicAPI",
                    apiVersion = ApiVersion,
                    requestID = Guid.NewGuid().ToString(),
                    messageType = "InjectParameterDataRequest",
                    data = new
                    {
                        faceFound = true,
                        parameterValues = paramsList.Select(p => new { id = p.Id, value = p.Value }).ToArray()
                    }
                };

                // Broadcast Mapping Updates
                var now = DateTime.Now;
                if ((now - _lastBroadcastTime).TotalMilliseconds >= 100)
                {
                    var update = new MappingUpdate();
                    foreach (var kvp in capturedData.Blendshapes) update.ArkitParams[kvp.Key] = kvp.Value;
                    foreach (var p in paramsList) update.VtsParams[p.Id] = p.Value;
                    MappingUpdated?.Invoke(update);
                    _lastBroadcastTime = now;
                }

                try
                {
                    var jsonString = JsonSerializer.Serialize(payload);
                    var bytes = Encoding.UTF8.GetBytes(jsonString);
                    await _webSocket!.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, token);
                    
                    // Consume the exact response message completely so buffer doesn't desync
                    WebSocketReceiveResult result;
                    do
                    {
                        result = await _webSocket.ReceiveAsync(new ArraySegment<byte>(receiveBuffer), token);
                    } while (!result.EndOfMessage);
                    
                    await Task.Delay(16, token); // roughly 60fps
                }
                catch (Exception ex)
                {
                    AppLogger.Log("VTS", $"Injection error: {ex.Message}");
                    break;
                }
            }

            _injectionLoopRunning = false;

            if (_shouldReconnect && !token.IsCancellationRequested)
            {
                CleanupConnection();
                Reconnect();
            }
        }
    }
}
