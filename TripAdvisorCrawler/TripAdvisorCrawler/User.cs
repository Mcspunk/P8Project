using MongoDB.Bson.Serialization.Attributes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TripAdvisorCrawler
{
    public class User
    {
        [BsonId()]
        public string uid;
        //public List<int> given_reviews;
    }
}
