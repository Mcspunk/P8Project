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
            Crawler crawler = new Crawler("https://www.tripadvisor.com/Attractions-g186338-Activities-London_England.html");
            //Crawler crawler = new Crawler("https://www.tripadvisor.com/Restaurants-g186338-London_England.html#EATERY_OVERVIEW_BOX");
            crawler.Crawl();
            Console.ReadKey();
        }
    }
}
