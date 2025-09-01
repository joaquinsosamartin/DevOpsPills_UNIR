using Microsoft.AspNetCore.Mvc;
using MathLibrary;

namespace PrimeNumbersWebApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PrimesController : ControllerBase
{
    [HttpGet("{number}")]
    [ProducesResponseType(typeof(bool), StatusCodes.Status200OK)]
    public ActionResult<bool> GetPrime(int number)
    {
        return PrimeService.IsPrime(number);
    }
}
