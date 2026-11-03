namespace Demo.Interop;

/// <summary>
/// A .NET static. Used by 06-pasoe to find out whether the
/// sessions of one PASOE agent share it. Result: they do not - each ABL
/// session loads Demo.Interop into its own AssemblyLoadContext ("AS-<n>").
/// </summary>
public static class Counter
{
    private static int _value;

    public static int Next() => Interlocked.Increment(ref _value);
}
