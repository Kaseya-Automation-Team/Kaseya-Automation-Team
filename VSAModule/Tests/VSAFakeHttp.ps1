# Shared test transport (F-67).
#
# Since v1.5.1 the module has a single HTTP stack built on System.Net.Http.HttpClient, so tests no
# longer simulate failures by mocking Invoke-RestMethod. Instead they install a fake
# HttpMessageHandler, which is the supported way to test HttpClient code: the real transport runs --
# its retry loop, status handling, Retry-After parsing, body reading and error typing are all
# genuinely exercised -- while the network is replaced by a scripted queue of responses.
#
# The injection seam is the module's own client cache ($script:VSAHttpClients), so no test-only hook
# exists in production code. Tests must clear that cache afterwards (see Reset-VSAFakeTransport
# usage) so subsequent code rebuilds a real client.
#
# NOTE: this file is deliberately NOT named *.Tests.ps1 -- it is dot-sourced by test files, not run
# as a test file itself.

if (-not ('FakeHttpMessageHandler' -as [type])) {
    $FakeHttpSource = @'
using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

public class FakeHttpExchange
{
    public int Status;
    public string Body;
    public int RetryAfterSeconds;
    public bool Fault;
}

// Returns scripted responses in FIFO order and records what was actually sent.
public class FakeHttpMessageHandler : HttpMessageHandler
{
    public Queue<FakeHttpExchange> Script = new Queue<FakeHttpExchange>();
    public List<string> RequestUris = new List<string>();
    public List<string> RequestBodies = new List<string>();
    public List<string> ContentTypes = new List<string>();
    public List<string> AuthHeaders = new List<string>();
    public List<string> Methods = new List<string>();
    public int CallCount = 0;

    public void EnqueueResponse(int status, string body, int retryAfterSeconds)
    {
        Script.Enqueue(new FakeHttpExchange { Status = status, Body = body, RetryAfterSeconds = retryAfterSeconds, Fault = false });
    }
    // Simulates no HTTP response at all (socket reset / unreachable / blocked endpoint).
    public void EnqueueFault()
    {
        Script.Enqueue(new FakeHttpExchange { Fault = true });
    }

    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        CallCount++;
        Methods.Add(request.Method.Method);
        RequestUris.Add(request.RequestUri.ToString());
        AuthHeaders.Add(request.Headers.Contains("Authorization") ? string.Join(",", request.Headers.GetValues("Authorization")) : null);
        if (request.Content != null)
        {
            RequestBodies.Add(request.Content.ReadAsStringAsync().Result);
            ContentTypes.Add(request.Content.Headers.Contains("Content-Type") ? string.Join(",", request.Content.Headers.GetValues("Content-Type")) : null);
        }
        else { RequestBodies.Add(null); ContentTypes.Add(null); }

        if (Script.Count == 0)
            throw new InvalidOperationException("FakeHttpMessageHandler: no scripted exchange left for " + request.RequestUri);

        FakeHttpExchange x = Script.Dequeue();
        if (x.Fault) throw new HttpRequestException("simulated connection reset");

        var resp = new HttpResponseMessage((HttpStatusCode)x.Status);
        resp.Content = new StringContent(x.Body ?? string.Empty, Encoding.UTF8, "application/json");
        if (x.RetryAfterSeconds > 0)
            resp.Headers.RetryAfter = new RetryConditionHeaderValue(TimeSpan.FromSeconds(x.RetryAfterSeconds));
        return Task.FromResult(resp);
    }
}
'@

    # The framework reference set differs by edition; 5.1 resolves System.Net.Http from the GAC.
    $FakeHttpRefs = if ($PSVersionTable.PSEdition -eq 'Core') {
        @('System.Net.Http', 'System.Net.Primitives', 'System.Runtime', 'System.Collections', 'System.Threading.Tasks', 'netstandard')
    } else {
        @('System.Net.Http')
    }
    Add-Type -TypeDefinition $FakeHttpSource -ReferencedAssemblies $FakeHttpRefs -ErrorAction Stop
}
