using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TripAdvisorCrawler
{
    class Program
    {
        static void Main(string[] args)
        {
            //Crawler crawler = new Crawler("https://www.tripadvisor.dk/Attractions-g186338-Activities-London_England.html");
            Crawler crawler = new Crawler("https://www.tripadvisor.dk/Restaurants-g186338-London_England.html");
            crawler.Crawl();
            Console.ReadKey();
        }
    }
}
