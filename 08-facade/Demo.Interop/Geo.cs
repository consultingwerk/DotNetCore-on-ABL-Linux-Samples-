namespace Demo.Interop;

/// <summary>
/// The Haversine distance in one call, for comparison with 05-benchmarks/wl-haversine.p:
/// the same maths, but crossing the ABL/.NET bridge once
/// per distance instead of 13 times.
/// </summary>
public static class Geo
{
    public static double DistanceKm(double lat1, double lon1, double lat2, double lon2)
    {
        static double Deg2Rad(double deg) => deg * Math.PI / 180;

        double dLat = Deg2Rad(lat2 - lat1);
        double dLon = Deg2Rad(lon2 - lon1);
        double a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2)
                 + Math.Cos(Deg2Rad(lat1)) * Math.Cos(Deg2Rad(lat2))
                 * Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

        return 6371 * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
    }
}
