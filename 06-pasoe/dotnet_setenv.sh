# .NET for the ABL agents of this instance. The agent (_mproapsv) is started by
# the Tomcat JVM and inherits this environment; without DOTNET_ROOT a user-local
# .NET in ~/.dotnet is not found.
DOTNET_ROOT="$HOME/.dotnet"; export DOTNET_ROOT
