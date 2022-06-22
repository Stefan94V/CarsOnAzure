using System.Text.Json.Serialization;
using Azure.Storage.Blobs;
using Cars.Api.Configuration;
using Cars.Api.Models;
using Microsoft.Extensions.Options;
using System.Text.Json;
namespace Cars.Api.Implementation;

public class CarService : ICarService
{
    private IOptions<AzureSettingsOptions> _options;
    private static Car[]? _cars;

    public CarService(IOptions<AzureSettingsOptions> options)
    {
        _options = options;
    }

    public async Task<string[]> GetModelsByBrand(string brand)
    {
        await SyncData();
        
        return _cars
            .Where(c => c.Brand.Equals(brand, StringComparison.InvariantCultureIgnoreCase))
            .Select(c => c.Models)
            .FirstOrDefault();
    }

    private async Task SyncData()
    {
        if (_cars is null or { Length: 0})
            _cars = await GetCars();
    }

    private async Task<Car[]?> GetCars()
    {
        var client = new BlobServiceClient(_options.Value.AzureStorageConnectionString);
        var container = client.GetBlobContainerClient(_options.Value.CarsContainerName);
        var blob = container.GetBlobClient(_options.Value.CarsJsonFileName);
        
        var fileInfo = await blob.DownloadStreamingAsync();
        
        return await JsonSerializer.DeserializeAsync<Car[]>(fileInfo.Value.Content);
    }
}