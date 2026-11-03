using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text.Json;

namespace Demo.Interop;

/// <summary>
/// A thin facade for ABL: plain string in, plain string out.
/// Everything ABL finds awkward (casts, struct arrays, Span overloads,
/// extension methods) stays on this side of the bridge.
/// </summary>
public static class Certs
{
    /// <summary>Checks a certificate against a CA we trust explicitly; returns JSON.</summary>
    public static string Check(string certPath, string caPath)
    {
        using var cert = new X509Certificate2(certPath);
        using var ca = new X509Certificate2(caPath);
        using var chain = new X509Chain();

        chain.ChainPolicy.TrustMode = X509ChainTrustMode.CustomRootTrust;
        chain.ChainPolicy.RevocationMode = X509RevocationMode.NoCheck;
        chain.ChainPolicy.CustomTrustStore.Add(ca);

        bool valid = chain.Build(cert);

        return JsonSerializer.Serialize(new
        {
            subject = cert.Subject,
            issuer = cert.Issuer,
            notAfterUtc = cert.NotAfter.ToUniversalTime().ToString("o"),
            daysLeft = (int)(cert.NotAfter - DateTime.Now).TotalDays,
            valid,
            reasons = chain.ChainStatus.Select(s => $"{s.Status} - {s.StatusInformation.Trim()}").ToArray()
        });
    }

    /// <summary>
    /// RSA.ImportFromPem takes ReadOnlySpan&lt;char&gt;, which ABL cannot bind to
    /// (error 14457). One line of C# makes it reachable with a string.
    /// </summary>
    public static int RsaKeySizeFromPem(string pem)
    {
        using var rsa = RSA.Create();
        rsa.ImportFromPem(pem);
        return rsa.KeySize;
    }
}
