using System.Text.Json.Serialization;

namespace CarsOnAzureFunctions.Models;

public class VehicleBrand
{
    [JsonPropertyName("name")]
    public string Name { get; set; }
    [JsonPropertyName("models")]
    public string[] Models { get; set; }
}