using Cars.Api.Models;

namespace Cars.Api.Implementation;

public interface ICarService
{
    Task<string[]> GetModelsByBrand(string brand);
}