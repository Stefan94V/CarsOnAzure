namespace Cars.Api.Configuration;

public class AzureSettingsOptions
{
    public string AzureStorageConnectionString { get; set; }
    public string CarsContainerName { get; set; }
    public string CarsJsonFileName { get; set; }
}