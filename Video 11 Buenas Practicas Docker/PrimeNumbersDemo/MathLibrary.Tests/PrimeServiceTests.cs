using Xunit;

namespace MathLibrary.Tests;

public class PrimeServiceTests
{
    [Theory]
    [InlineData(1, false)]
    [InlineData(2, true)]
    [InlineData(3, true)]
    [InlineData(4, false)]
    [InlineData(13, true)]
    [InlineData(15, false)]
    public void IsPrime_ReturnsExpected(int value, bool expected)
    {
        var result = PrimeService.IsPrime(value);
        Assert.Equal(expected, result);
    }
}
