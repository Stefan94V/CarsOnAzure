using System.Text.Json.Serialization;

namespace Cars.Api.Models;

public record Car(
    [property: JsonPropertyName("brand")] string Brand, 
    [property: JsonPropertyName("models")] string[] Models);