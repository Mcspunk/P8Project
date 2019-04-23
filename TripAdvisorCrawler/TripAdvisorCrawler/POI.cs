using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace TripAdvisorCrawler
{
    public class POI
    {
        public int id;

        public List<Review> reviews;

        public double lat;

        public double lng;

        public double avgRating;

        public Dictionary<string, List<string>> openingshours;

        public string address;

        public string city;

        public string category;

        public string imgURL;

        public string name;

        public int priceLevel = -1;

        public string openingHoursString()
        {
            var resultString = "";
            foreach (var item in openingshours)
            {
                resultString += item.Key;
                resultString += ":";
                foreach (var time in item.Value)
                {
                    resultString += time;
                    resultString += ";";
                }
                resultString += '\n';
            }
            return resultString;
        }
    }
}
