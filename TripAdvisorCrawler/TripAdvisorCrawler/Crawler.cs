using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using HtmlAgilityPack;
using Newtonsoft.Json;


namespace TripAdvisorCrawler
{
    public class Crawler
    {
        private string seed;
        private string tripadvisor = "https://tripadvisor.com";
        public List<POI> results = new List<POI>();
        public Crawler(string seed)
        {
            this.seed = seed;
        }

        public void Crawl()
        {
            ProcessNewPage(seed);
        }

        public void ProcessNewPage(string pageUrl)
        {
            HtmlWeb web = new HtmlWeb();
            HtmlDocument doc = web.Load(pageUrl);
            var ele = doc.GetElementbyId("FILTERED_LIST");
            try
            {
                var e = ele.ChildNodes[1].ChildNodes[0].ChildNodes[1].ChildNodes[2];
                var attLink = e.InnerHtml.Split('\"')[3];
                var innerDoc = web.Load(tripadvisor + attLink);
                var contextScriptNode = innerDoc.DocumentNode.SelectNodes("//script")[1];
                dynamic array = JsonConvert.DeserializeObject(contextScriptNode.InnerHtml);
                POI newPOI = new POI();
                newPOI.name = array["name"];
                newPOI.imgURL = array["image"];
                newPOI.avgRating = Convert.ToDouble(array["aggregateRating"]["ratingValue"]);
                newPOI.address = array["address"]["streetAddress"];
                newPOI.city = array["address"]["addressLocality"];
                var headerInfoNode = innerDoc.GetElementbyId("taplc_resp_attraction_header_ar_responsive_0");
                newPOI.category = headerInfoNode.ChildNodes[0].ChildNodes[0].ChildNodes[1].ChildNodes[2].ChildNodes[0].ChildNodes[0].InnerText;
                var openingPopup = innerDoc.GetElementbyId("c_popover_2");
                var openingUl = openingPopup.ChildNodes[0].ChildNodes[0].ChildNodes[1].ChildNodes[0].ChildNodes[1];
                foreach (var openingli in openingUl.ChildNodes)
                {
                    newPOI.openingshours.Add(openingli.ChildNodes[0].InnerText, openingli.ChildNodes[1].InnerText);
                }
                Console.WriteLine("hejsa");
            }
            catch (Exception)
            {

                throw;
            }

        }



    }
}
