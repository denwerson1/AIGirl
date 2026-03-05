using System.Text.Json;

string baseUrl =
    args.Length > 0 ? args[0] :
    Environment.GetEnvironmentVariable("AIGIRL_API") ?? "http://127.0.0.1:8000";

baseUrl = baseUrl.TrimEnd('/');

using var http = new HttpClient
{
    BaseAddress = new Uri(baseUrl + "/"),
    Timeout = TimeSpan.FromSeconds(10)
};

Console.WriteLine($"AIGirl.Client");
Console.WriteLine($"BaseAddress: {http.BaseAddress}");
Console.WriteLine();

async Task TryGetString(string path)
{
    try
    {
        var s = await http.GetStringAsync(path);
        Console.WriteLine($"GET /{path} -> OK");
        Console.WriteLine(s.Length > 600 ? s[..600] + "..." : s);
        Console.WriteLine();
    }
    catch (Exception ex)
    {
        Console.WriteLine($"GET /{path} -> FAIL: {ex.Message}");
        Console.WriteLine();
    }
}

await TryGetString("health");

try
{
    using var stream = await http.GetStreamAsync("openapi.json");
    using var doc = await JsonDocument.ParseAsync(stream);
    var info = doc.RootElement.GetProperty("info");
    var title = info.TryGetProperty("title", out var t) ? t.GetString() : "(no title)";
    var version = info.TryGetProperty("version", out var v) ? v.GetString() : "(no version)";
    Console.WriteLine($"GET /openapi.json -> OK");
    Console.WriteLine($"OpenAPI: {title}  version: {version}");
}
catch (Exception ex)
{
    Console.WriteLine($"GET /openapi.json -> FAIL: {ex.Message}");
}

Console.WriteLine();
Console.WriteLine("Done.");
