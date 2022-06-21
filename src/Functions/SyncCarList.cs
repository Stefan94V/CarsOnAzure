using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using Azure.Storage.Blobs.Models;
using Azure.Storage.Blobs.Specialized;
using CarsOnAzureFunctions.Models;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace CarsOnAzureFunctions
{
    public class SyncCarList
    {
        [FunctionName("SyncCarList")]
        public async Task Run(
            [TimerTrigger("0 0 * * * FRI", RunOnStartup = true)]TimerInfo myTimer, 
            ILogger log,
            [Blob("output//cars.json", FileAccess.ReadWrite)] BlockBlobClient client)
        {
            log.LogInformation($"C# Timer trigger function executed at: {DateTime.Now}");
            var url = new Uri(Environment.GetEnvironmentVariable("CarsUrl") ?? throw new Exception("CarsUrl not set"));
            var carsResultAsStream = await GetCars(url);

            await client.UploadAsync(carsResultAsStream,
                new BlobHttpHeaders() { ContentType = "application/json" });
        }

        private Task<Stream> GetCars(Uri carUri)
        {
            var client = new HttpClient()
            {
                BaseAddress = carUri
            };
            return client.GetStreamAsync(string.Empty);
        }
    }
}
