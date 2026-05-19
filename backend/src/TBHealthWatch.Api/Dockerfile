FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY TBHealthWatch.sln ./
COPY src/TBHealthWatch.Api/TBHealthWatch.Api.csproj src/TBHealthWatch.Api/
COPY src/TBHealthWatch.Application/TBHealthWatch.Application.csproj src/TBHealthWatch.Application/
COPY src/TBHealthWatch.Domain/TBHealthWatch.Domain.csproj src/TBHealthWatch.Domain/
COPY src/TBHealthWatch.Infrastructure/TBHealthWatch.Infrastructure.csproj src/TBHealthWatch.Infrastructure/

RUN dotnet restore src/TBHealthWatch.Api/TBHealthWatch.Api.csproj

COPY src/ src/

RUN dotnet publish src/TBHealthWatch.Api/TBHealthWatch.Api.csproj \
    -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

EXPOSE 8080
ENTRYPOINT ["dotnet", "TBHealthWatch.Api.dll"]
