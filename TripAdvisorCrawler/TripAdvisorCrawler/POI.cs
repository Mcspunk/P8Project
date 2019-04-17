using MongoDB.Bson.Serialization.Attributes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace TripAdvisorCrawler
{
    public class POI
    {
        [BsonId]
        public int id;

        [BsonIgnore]
        public List<Review> reviews;

        [BsonElement("lat")]
        public double lat;

        [BsonElement("lng")]
        public double lng;

        [BsonElement("avg_rating")]
        public double avgRating;

        public Dictionary<string, List<string>> openingshours;

        [BsonElement("address")]
        public string address;

        [BsonElement("city")]
        public string city;

        [BsonElement("category")]
        public string category;

        [BsonElement("imgURL")]
        public string imgURL;

        [BsonElement("name")]
        public string name;

        [BsonElement("price_level")]
        public int priceLevel;
    }
}
