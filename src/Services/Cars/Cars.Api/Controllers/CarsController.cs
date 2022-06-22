using Cars.Api.Implementation;
using Microsoft.AspNetCore.Mvc;

namespace Cars.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CarsController : ControllerBase
{
    private readonly ILogger<CarsController> _logger;
    private readonly ICarService _carService;

    public CarsController(ILogger<CarsController> logger, ICarService carService)
    {
        _logger = logger;
        _carService = carService;
    }

    [HttpGet]
    public async Task<IActionResult> GetByBrand([FromQuery] string brand)
    {
        var modelsByBrand = await _carService.GetModelsByBrand(brand);

        if (modelsByBrand is null or { Length: 0 })
            return NotFound();

        return Ok(modelsByBrand);
    }
}